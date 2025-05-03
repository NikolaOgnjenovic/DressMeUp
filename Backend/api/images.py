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

        # Base64 encode image
        image_bytes = response.content
        base64_image = base64.b64encode(image_bytes).decode("utf-8")

        client = genai.Client(api_key=GEMINI_API_KEY)

        # Identify clothing with simplified prompt
        identification_response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[
                base64_image,
                """List clothing items in this image as JSON with labels and positions:
                {"clothing_items": [{"label": "item1", "position": {"x1":0,"y1":0,"x2":100,"y2":100}}]}"""
            ]
        )

        # Extract clothing items
        clothing_items = identification_response.candidates[0].content.parts[0].text
        clothing_items = eval(clothing_items)["clothing_items"]

        saved_items = []
        for item in clothing_items:
            x1, y1, x2, y2 = item["position"].values()
            cropped_image = crop_image(base64_image, x1, y1, x2, y2)

            # Simplified segmentation prompt
            segment_response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[
                    cropped_image,
                    f"""Remove background from this {item['label']} and return as base64 PNG:
                    {{"label": "{item['label']}", "image": "base64_data"}}"""
                ]
            )

            # Process segment response
            segment_data = eval(segment_response.candidates[0].content.parts[0].text)
            image_data = base64.b64decode(segment_data["image"])

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


def crop_image(base64_img, x1, y1, x2, y2):
    img_data = base64.b64decode(base64_img)
    img = Image.open(io.BytesIO(img_data))
    cropped_img = img.crop((x1, y1, x2, y2))

    buffered = io.BytesIO()
    cropped_img.save(buffered, format="PNG")
    return base64.b64encode(buffered.getvalue()).decode("utf-8")