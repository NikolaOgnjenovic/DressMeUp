import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/dressmeup")
# Configuration
IMGUR_API_URL = "https://api.imgur.com/3/image"
IMGUR_CLIENT_ID = "dc6945bad2c734e"
PRODUCT_SEARCH_URL = "https://api.inditex.com/pubvsearch"

OAUTH_CREDENTIALS = {
    "username": "oauth-mkplace-oauthfzwgzhghllpbhrtxwbpropro",
    "password": "k5i~z21}Yr[wAk.E",
    "grant_type": "client_credentials",
    "scope": "technology.catalog.read"
}
OAUTH_TOKEN_URL = "https://auth.inditex.com:443/openam/oauth2/itxid/itxidmp/access_token"
GEMINI_API_KEY = "AIzaSyBm4zOPmR8WsjXVPgQbX9pPVgKWPIPKkXM"
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

# Production
# PRODUCT_SEARCH_URL = "https://api.inditex.com/pubvsearch"
#
# OAUTH_CREDENTIALS = {
#     "username": "oauth-mkplace-oauthfzwgzhghllpbhrtxwbpropro",
#     "password": "k5i~z21}Yr[wAk.E",
#     "grant_type": "client_credentials",
#     "scope": "technology.catalog.read"
# }
# OAUTH_TOKEN_URL = "https://auth.inditex.com:443/openam/oauth2/itxid/itxidmp/access_token"

# Sandbox
# PRODUCT_SEARCH_URL = "https://api-sandbox.inditex.com/pubvsearch-sandbox"
#
# OAUTH_CREDENTIALS = {
#     "username": "oauth-mkpsbox-oauthunuzbwosdzjcmkzsyhsnbxpro",
#     "password": "]o_2_L9vIXQ1lh6I",
#     "grant_type": "client_credentials",
#     "scope": "technology.catalog.read"
# }
# OAUTH_TOKEN_URL = "https://auth.inditex.com:443/openam/oauth2/itxid/itxidmp/sandbox/access_token"