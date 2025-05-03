from sqlmodel import create_engine, SQLModel, Session
from models import get_all_models
from core import secrets

engine = create_engine(
        secrets.DATABASE_URL,
        echo=True,
        pool_size=10,
        max_overflow=5
        )

def create_db_and_tables(drop_all: bool = False):
    _ = get_all_models()
    with engine.begin() as conn:
        if drop_all:
            SQLModel.metadata.drop_all(conn)
        SQLModel.metadata.create_all(conn)

def get_db():
    db = Session(engine)
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()
