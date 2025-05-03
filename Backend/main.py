from fastapi import FastAPI
from contextlib import asynccontextmanager
from starlette.middleware.cors import CORSMiddleware

from db import db
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