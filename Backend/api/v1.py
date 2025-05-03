from fastapi import APIRouter

from api import images
from api import search

v1 = APIRouter(
        prefix="/v1"
        )

v1.include_router(images.router)
v1.include_router(search.router)