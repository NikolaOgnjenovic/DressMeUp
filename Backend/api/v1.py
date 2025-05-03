from fastapi import APIRouter

from api import images

v1 = APIRouter(
        prefix="/v1"
        )

v1.include_router(images.router)
