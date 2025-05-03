from datetime import datetime
from typing import Annotated, List
from fastapi import APIRouter, UploadFile, File, Depends, status, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select
import httpx
import base64

from db import db
import models
from core.secrets import *
from models.models import UploadedImage, SegmentedClothing

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


@router.post("/segment/{image_id}",
             status_code=status.HTTP_200_OK,
             response_model=SegmentedImageResponse)
async def segment_clothing(
        image_id: int,
        db: Annotated[Session, Depends(db.get_db)]
):
    try:
        # Get the original image from database
        db_image = db.get(UploadedImage, image_id)
        if not db_image:
            raise HTTPException(status_code=404, detail="Image not found")

        # Download the image from Imgur
        async with httpx.AsyncClient() as client:
            response = await client.get(db_image.imgur_url)

        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Failed to download image from Imgur: {response.status_code}"
            )

        image_bytes = response.content
        base64_image = base64.b64encode(image_bytes).decode("utf-8")

        # Prepare Gemini API request
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {GEMINI_API_KEY}"
        }

        # This prompt asks Gemini to segment the image into clothing items
        # and return them as separate base64 encoded images with labels
        payload = {
            "key": GEMINI_API_KEY,
            "contents": [{
                "parts": [{
                    "text": f"""Analyze this image and identify all clothing items (t-shirts, pants, hats, etc.). 
                    For each clothing item found, extract it as a separate image with a transparent background 
                    (remove the background), and label it with the appropriate clothing type. 
                    Return each segmented clothing item as a base64 encoded PNG image along with its label 
                    in this exact JSON format: 
                    {{
                        "clothing_items": [
                            {{
                                "label": "t-shirt",
                                "image": "base64_encoded_image_data"
                            }},
                            // ... more items if present
                        ]
                    }}""",
                    "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": base64_image
                    }
                }]
            }]
        }

        # Call Gemini API
        async with httpx.AsyncClient() as client:
            response = await client.post(
                GEMINI_API_URL,  # Make sure this is defined in your secrets
                headers=headers,
                json=payload
            )

        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Gemini API request failed: {response.text}"
            )

        # Parse Gemini response
        try:
            response_data = response.json()
            # Gemini returns the text in the 'text' field of the first candidate
            gemini_response_text = response_data["candidates"][0]["content"]["parts"][0]["text"]

            # The response should be a JSON string, so we need to parse it
            import json
            segmented_data = json.loads(gemini_response_text)
            clothing_items = segmented_data.get("clothing_items", [])

            if not clothing_items:
                raise HTTPException(
                    status_code=400,
                    detail="No clothing items found in the image"
                )

            # Upload each segmented clothing item to Imgur and save to database
            saved_items = []
            for item in clothing_items:
                # Decode the base64 image
                image_data = base64.b64decode(item["image"])

                # Upload to Imgur
                headers = {"Authorization": f"Client-ID {IMGUR_CLIENT_ID}"}
                files = {"image": ("clothing.png", image_data)}

                async with httpx.AsyncClient() as client:
                    upload_response = await client.post(
                        IMGUR_API_URL,
                        headers=headers,
                        files=files
                    )

                if upload_response.status_code == 200:
                    upload_data = upload_response.json()
                    imgur_url = upload_data["data"]["link"]

                    # Save to database
                    db_clothing = SegmentedClothing(
                        original_image_id=image_id,
                        label=item["label"],
                        image_url=imgur_url,
                        segmentation_date=datetime.utcnow()
                    )
                    db.add(db_clothing)
                    saved_items.append({
                        "label": item["label"],
                        "image_url": imgur_url
                    })

            db.commit()

            return {
                "original_image_id": image_id,
                "clothing_items": saved_items,
                "segmentation_date": datetime.utcnow()
            }

        except (json.JSONDecodeError, KeyError, IndexError) as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to parse Gemini response: {str(e)}. Response: {gemini_response_text}"
            )

    except Exception as e:
        raise HTTPException(
            status_code=400,
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


@router.get("/segmented/{image_id}",
            status_code=status.HTTP_200_OK,
            response_model=List[ClothingItem])
async def get_segmented_clothing(
        image_id: int,
        db: Annotated[Session, Depends(db.get_db)]
):
    try:
        clothing_items = db.exec(
            select(SegmentedClothing)
            .where(SegmentedClothing.original_image_id == image_id)
            .order_by(SegmentedClothing.segmentation_date.desc())
        ).all()

        return [
            {
                "label": item.label,
                "image_url": item.image_url
            }
            for item in clothing_items
        ]
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving segmented clothing: {str(e)}"
        )