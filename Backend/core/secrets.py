import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/dressmeup")
# Configuration
IMGUR_API_URL = "https://api.imgur.com/3/image"
IMGUR_CLIENT_ID = "dc6945bad2c734e"
PRODUCT_SEARCH_URL = "https://api-sandbox.inditex.com/pubvsearch-sandbox"

