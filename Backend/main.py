from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from contextlib import asynccontextmanager
from fastapi.responses import JSONResponse
import httpx
from starlette.middleware.cors import CORSMiddleware
from datetime import datetime
from sqlalchemy.orm import Session

import models
from db import db
from services.product_search_service import ProductSearchService
from api import v1
@asynccontextmanager
async def lifespan(app: FastAPI):
    db.create_db_and_tables()
    yield
    db.engine.dispose()


app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(v1.v1)
"""
# Initialize service
product_search_service = ProductSearchService(
    base_url=PRODUCT_SEARCH_URL
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


        """
