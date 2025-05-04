import json
from datetime import datetime
from typing import Annotated, List
from fastapi import APIRouter, UploadFile, File, Depends, status, HTTPException
from google import genai
from pydantic import BaseModel
from sqlmodel import Session, select
import httpx
import base64

from db import db
import models
from core.secrets import *
from db.db import get_db
from models.models import UploadedImage, SegmentedClothing
from PIL import Image
import io

router = APIRouter(
    prefix="/images",
)


class ImageUploadResponse(BaseModel):
    id: int
    imgur_url: str
    upload_date: datetime | None = None


class ClothingItem(BaseModel):
    label: str
    image_url: str


class SegmentedImageResponse(BaseModel):
    original_image_id: int
    clothing_items: List[ClothingItem]
    segmentation_date: datetime


@router.post("/",
             status_code=status.HTTP_200_OK,
             response_model=ImageUploadResponse)
async def upload_image(
        file: Annotated[UploadFile, File(...)],
        db: Annotated[Session, Depends(db.get_db)]
):
    try:
        file_content = await file.read()

        headers = {"Authorization": f"Client-ID {IMGUR_CLIENT_ID}"}
        files = {"image": (file.filename, file_content)}

        async with httpx.AsyncClient() as client:
            response = await client.post(
                IMGUR_API_URL,
                headers=headers,
                files=files
            )

        if response.status_code == 200:
            data = response.json()
            imgur_url = data["data"]["link"]

            # Store in database
            db_image = models.UploadedImage(
                original_filename=file.filename,
                imgur_url=imgur_url,
            )
            db.add(db_image)
            db.commit()
            db.refresh(db_image)

            return {
                "id": db_image.id,
                "imgur_url": db_image.imgur_url,
                "upload_date": db_image.upload_date
            }
        else:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Imgur upload failed with status: {response.status_code}"
            )
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )

# Segment an image with the provided id into an image for each piece of clothing.
# The clothing piece images are on a transparent background and are optimal for the Inditex API.
@router.post("/segment/{image_id}",
             status_code=status.HTTP_200_OK,
             response_model=SegmentedImageResponse)
async def segment_clothing(
        image_id: int,
        db: Annotated[Session, Depends(get_db)]
):
    try:
        # Retrieve the original image details
        db_image = db.get(UploadedImage, image_id)
        if not db_image:
            raise HTTPException(status_code=404, detail="Image not found")

        client = genai.Client(api_key=GEMINI_API_KEY)

        # Download the image as base64
        async with httpx.AsyncClient() as http_client:
            img_response = await http_client.get(db_image.imgur_url)
            if img_response.status_code != 200:
                raise HTTPException(status_code=400, detail="Failed to download image")
            image_bytes = img_response.content
            base64_image = base64.b64encode(image_bytes).decode("utf-8")

        # --- First Gemini Prompt: Detailed Clothing Item Detection ---
        identification_response = client.models.generate_content(
            model="gemini-1.5-flash",
            contents=[
                {
                    "role": "user",
                    "parts": [
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": base64_image
                            }
                        },
                        {
                            "text": """Analyze the provided image of an outfit and identify each distinct clothing item (e.g., top, bottom, shoes, accessories). For each item, provide a detailed description including:

*   **Type of item:** (e.g., t-shirt, jeans, sneakers, necklace)
*   **Material:** (e.g., cotton, denim, leather, silk)
*   **Color:** (e.g., navy blue, light wash, bright red, silver)
*   **Pattern/Print:** (e.g., solid, striped, floral, geometric)
*   **Style/Fit:** (e.g., slim fit, oversized, cropped, high-waisted)
*   **Distinguishing features:** (e.g., button-down, ripped knees, platform sole, pendant)
*   **Any visible brand logos or text** (Describe the logo or text as accurately as possible)
Output the descriptions as a json list of long string, where every string represents an item description from which i will be able to generate a picture of the item. return json and json only, without any markdown formatting. I repeat, NO MARKDOWN formatting, no asterisks, just plain text
"""
                        }
                    ]
                }
            ]
        )

        # Extract and parse the detailed clothing item descriptions
        response_text = identification_response.candidates[0].content.parts[0].text[7:-4]
        try:
            # Attempt to parse the JSON response
            clothing_data = json.loads(response_text)
            if not isinstance(clothing_data, list):
                raise ValueError("Gemini response was not a JSON array.")
        except json.JSONDecodeError as e:
            raise HTTPException(
                status_code=400,
                detail=f"Failed to parse Gemini response as JSON: {str(e)}. Response: {response_text}"
            )

        saved_items = []
        for item_data in clothing_data:
            # --- Second Gemini Prompt: Transparent Image Generation ---
            segmentation_response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[
                    {
                        "role": "user",
                        "parts": [
                            {
                                "text": f"""Generate a photorealistic image of a clothing item based on the following description: {item_data}. The image should:

*   Display the clothing item on a transparent background.
*   Show the clothing item in a clear, well-lit, and professional manner, as if photographed for an online retail store.
*   Capture all the key details described, including the material, color, pattern/print, style/fit, and distinguishing features.
*   Be suitable for product display on an e-commerce website.
                                Return ONLY the base64 encoded string of the PNG image.
                                Provide the FULL valid base64 image string that can be decoded."""
                            }
                        ]
                    }
                ]
            )
            label = 'label'

            try:
                segment_text = segmentation_response.candidates[0].content.parts[0].text.strip()
                print(segment_text)
                image_data = base64.b64decode(segment_text)

                # Upload the segmented image to Imgur
                headers = {"Authorization": f"Client-ID {IMGUR_CLIENT_ID}"}
                files = {"image": ("segmented_clothing.png", image_data)}

                async with httpx.AsyncClient() as http_client:
                    upload_response = await http_client.post(
                        IMGUR_API_URL,
                        headers=headers,
                        files=files
                    )

                if upload_response.status_code == 200:
                    upload_data = upload_response.json()
                    imgur_url = upload_data["data"]["link"]


                    # Save the segmented clothing item to the database
                    db_clothing = SegmentedClothing(
                        original_image_id=image_id,
                        label=label,
                        image_url=imgur_url,
                        segmentation_date=datetime.utcnow()
                    )
                    db.add(db_clothing)
                    saved_items.append({
                        "label": label,
                        "image_url": imgur_url
                    })
                else:
                    print(f"Warning: Imgur upload failed for {label} with status code: {upload_response.status_code}, response: {upload_response.text}")

            except Exception as e:
                print(f"Warning: Failed to process or upload segmented image for {label}: {str(e)}")
                continue

        db.commit()

        return {
            "original_image_id": image_id,
            "clothing_items": saved_items,
            "segmentation_date": datetime.utcnow()
        }

    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

@router.get("/",
            status_code=status.HTTP_200_OK,
            response_model=List[ImageUploadResponse])
async def get_uploaded_images(
        db: Annotated[Session, Depends(db.get_db)]
):
    try:
        images = db.exec(select(UploadedImage).order_by(UploadedImage.upload_date.desc())).all()
        return [
            {
                "id": img.id,
                "imgur_url": img.imgur_url,
                "upload_date": img.upload_date
            }
            for img in images
        ]
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving images: {str(e)}"
        )