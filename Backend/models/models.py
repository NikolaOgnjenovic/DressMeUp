from datetime import datetime

from sqlalchemy.ext.declarative import declarative_base
from sqlmodel import Field, SQLModel

from models import register_model

Base = declarative_base()

@register_model
class UploadedImage(SQLModel, table=True, extra="ignore"):
    id: int | None = Field(
            primary_key=True,
            index=True,
            nullable=False)
    imgur_url: str = Field(...)
    upload_date: datetime = Field(
            default_factory=lambda: datetime.now())

@register_model
class CelebrityImage(SQLModel, table=True):
    id: int | None = Field(
        primary_key=True,
        index=True,
        nullable=False)
    original_filename: str
    image_url: str
    crawl_date: datetime = Field(default_factory=lambda: datetime.now())
    source: str
    celebrity_name: str

@register_model
class SegmentedClothing(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    original_image_id: int = Field(foreign_key="uploadedimage.id")
    label: str  # e.g., "t-shirt", "hat", etc.
    image_url: str  # URL to the segmented image
    segmentation_date: datetime = Field(default_factory=lambda: datetime.now())