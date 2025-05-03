from datetime import datetime
from typing import Annotated, List
from fastapi import APIRouter, UploadFile, File, Depends, status, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select
import httpx

from db import db
import models
from core.secrets import *
from models.models import UploadedImage

router = APIRouter(
        prefix="/images",
        )

class ImageUploadResponse(BaseModel):
    id: int
    imgur_url: str
    upload_date: datetime | None = None

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
                    "imgur_url": db_image.imgur_url
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

@router.get("/images",
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

