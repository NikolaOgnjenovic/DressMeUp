from typing import Optional, List

from fastapi import APIRouter, Depends, status, Query
from pydantic import BaseModel

from services.product_search_service import ProductSearchService, get_product_search_service

router = APIRouter(
    prefix="/products",
    tags=["products"]
)

class PriceValue(BaseModel):
    current: float
    original: Optional[float] = None

class PriceInfo(BaseModel):
    currency: str
    value: PriceValue

class ProductSearchResponse(BaseModel):
    brand: str
    id: Optional[str] = None
    link: str
    name: str
    price: PriceInfo


@router.get("/search",
            status_code=status.HTTP_200_OK,
            response_model=List[ProductSearchResponse])
async def search_products(
    image: str = Query(..., description="Image URL to search for products"),
    service: ProductSearchService = Depends(get_product_search_service)
):
    results = await service.search_products(image)
    return [
        ProductSearchResponse(
            brand=item['brand'],
            id=item['id'],
            link=item['link'],
            name=item['name'],
            price=PriceInfo(
                currency=item['price']['currency'],
                value=PriceValue(
                    current=item['price']['value']['current'],
                    original=item['price']['value']['original']
                )
            )
        )
        for item in results
    ]