from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import httpx
from starlette.middleware.cors import CORSMiddleware

from services.product_search_service import ProductSearchService

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only, restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
IMGUR_API_URL = "https://api.imgur.com/3/image"
IMGUR_CLIENT_ID = "dc6945bad2c734e"
PRODUCT_SEARCH_URL = "https://api-sandbox.inditex.com/pubvsearch-sandbox"

# Initialize service
product_search_service = ProductSearchService(
    base_url=PRODUCT_SEARCH_URL
)


@app.post("/upload/")
async def upload_image(file: UploadFile = File(...)):
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
            return JSONResponse(content={
                "link": data["data"]["link"]
            }, status_code=200)
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


@app.get("/products")
async def search_products(image: str):
    try:
        result = await product_search_service.search_products(image)
        return JSONResponse(content=result, status_code=200)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Unexpected error: {str(e)}"
        )