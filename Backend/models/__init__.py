from typing import List, Type

from sqlmodel import SQLModel

_registry: List[Type[SQLModel]] = []

def register_model(model: Type[SQLModel]) -> Type[SQLModel]:
    """Decorator for registering tables"""
    _registry.append(model)
    return model

def get_all_models() -> List[Type[SQLModel]]:
    return _registry.copy()

from .models import UploadedImage
from .models import CelebrityImage
