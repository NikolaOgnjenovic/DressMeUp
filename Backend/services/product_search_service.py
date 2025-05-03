import httpx
from fastapi import HTTPException
from datetime import datetime, timedelta
from core.secrets import PRODUCT_SEARCH_URL

async def get_product_search_service():
    return ProductSearchService(base_url=PRODUCT_SEARCH_URL)

class ProductSearchService:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.auth_token = None
        self.token_expiry = None
        # Hardcoded credentials from your curl command
        self.oauth_credentials = {
            "username": "oauth-mkpsbox-oauthunuzbwosdzjcmkzsyhsnbxpro",
            "password": "]o_2_L9vIXQ1lh6I",  # Empty password as per your curl command
            "grant_type": "client_credentials",
            "scope": "technology.catalog.read"
        }
        self.token_url = "https://auth.inditex.com:443/openam/oauth2/itxid/itxidmp/sandbox/access_token"

    async def get_token(self):
        # Check if we have a valid token
        if self.auth_token and self.token_expiry and self.token_expiry > datetime.now():
            return self.auth_token

        # Request new token
        auth = httpx.BasicAuth(
            username=self.oauth_credentials["username"],
            password=self.oauth_credentials["password"]
        )

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    self.token_url,
                    auth=auth,
                    data={
                        "grant_type": self.oauth_credentials["grant_type"],
                        "scope": self.oauth_credentials["scope"]
                    },
                    headers={
                        "User-Agent": "OpenPlatform/1.0",
                        "Content-Type": "application/x-www-form-urlencoded"
                    }
                )
                response.raise_for_status()
                token_data = response.json()

                # Set token and expiry (assuming 1 hour expiry if not provided)
                self.auth_token = token_data["id_token"]
                expires_in = token_data.get("expires_in", 3600)  # Default 1 hour
                self.token_expiry = datetime.now() + timedelta(seconds=expires_in)

                return self.auth_token

            except httpx.HTTPStatusError as e:
                raise HTTPException(
                    status_code=e.response.status_code,
                    detail=f"Token request failed: {e.response.text}"
                )
            except Exception as e:
                raise HTTPException(
                    status_code=500,
                    detail=f"Unexpected error during token request: {str(e)}"
                )

    async def search_products(self, image_link: str):
        try:
            # Get fresh token for each request
            token = await self.get_token()

            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "User-Agent": "OpenPlatform/1.0",
            }

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/products",
                    params={"image": image_link},
                    headers=headers
                )
                response.raise_for_status()
                return response.json()

        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=e.response.status_code,
                detail=f"Product search failed: {e.response.text}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Unexpected error: {str(e)}"
            )