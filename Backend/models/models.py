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