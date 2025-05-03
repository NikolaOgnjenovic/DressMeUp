from typing import Annotated, List, Optional, Tuple
from fastapi import APIRouter, Depends, status, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select
import requests
from bs4 import BeautifulSoup
import re
import random
from datetime import datetime
from urllib.parse import quote_plus
import json
import imghdr
from io import BytesIO
from db import db
from api.images import ImageUploadResponse
from models import CelebrityImage, models
from PIL import Image

router = APIRouter(
    prefix="/images",
    tags=["images"]
)

# Quality thresholds
HQ_MIN_WIDTH = 1200
HQ_MIN_HEIGHT = 1800
LQ_MAX_WIDTH = 800
LQ_MAX_HEIGHT = 1200


class CelebrityCrawlRequest(BaseModel):
    name: str
    max_images: int = 10
    require_hq: bool = False  # If True, will return error if no HQ images found


class ImageResponse(ImageUploadResponse):
    is_hq: bool
    width: Optional[int] = None
    height: Optional[int] = None


def verify_image_resolution(url: str) -> Tuple[bool, Optional[int], Optional[int]]:
    """Check if image meets HQ requirements"""
    try:
        response = requests.get(url, stream=True, timeout=10)
        response.raise_for_status()

        # Verify it's an image
        image_type = imghdr.what(None, response.content)
        if image_type not in ['jpeg', 'png', 'webp']:
            return False, None, None

        # Get dimensions without loading full image
        img = Image.open(BytesIO(response.content))
        width, height = img.size

        is_hq = width >= HQ_MIN_WIDTH and height >= HQ_MIN_HEIGHT

        return is_hq, width, height

    except Exception:
        return False, None, None


def get_hq_images_from_professional_sources(name: str, max_images: int) -> List[str]:
    """Try professional sources first (highest quality)"""
    # Implement API calls to services like:
    # - Getty Images
    # - Shutterstock
    # - Adobe Stock
    # (These require API keys and often payment)
    return []


def get_hq_images_from_google(name: str, max_images: int) -> List[str]:
    """Get largest available images from Google"""
    try:
        search_term = f"{name} outfit fashion red carpet street style high resolution"
        url = f"https://www.google.com/search?q={quote_plus(search_term)}&tbm=isch&tbs=isz:l,itp:photo"

        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }

        response = requests.get(url, headers=headers)
        response.raise_for_status()

        # Parse Google's JavaScript data
        soup = BeautifulSoup(response.text, 'html.parser')
        script_tags = soup.find_all('script')
        image_urls = []

        for script in script_tags:
            if 'AF_initDataCallback' in script.text:
                try:
                    # Extract image data from Google's complex JavaScript
                    json_str = re.search(r'AF_initDataCallback\({key:.*?data:(.*?), sideChannel:.*}\)',
                                         script.text).group(1)
                    data = json.loads(json_str)
                    flat_data = json.dumps(data)

                    # Find all image URLs
                    urls = re.findall(
                        r'\"(https?://[^\"]+\.(jpg|jpeg|png|webp))\"',
                        flat_data
                    )
                    image_urls.extend([url[0] for url in urls])
                except Exception:
                    continue

        return list(set(image_urls))[:max_images]  # Remove duplicates

    except Exception as e:
        print(f"Google Images error: {str(e)}")
        return []


def get_images_from_wikimedia(name: str, max_images: int) -> List[str]:
    """Get images from Wikimedia Commons with size info"""
    try:
        url = f"https://commons.wikimedia.org/w/api.php?action=query&generator=images&titles={quote_plus(name)}&prop=imageinfo&iiprop=url|size|mime&iiurlwidth=1200&format=json"
        response = requests.get(url)
        response.raise_for_status()

        data = response.json()
        images = []

        if 'query' in data and 'pages' in data['query']:
            for page in data['query']['pages'].values():
                if 'imageinfo' in page:
                    for info in page['imageinfo']:
                        if info['url'].endswith(('.jpg', '.jpeg', '.png')):
                            images.append(info['url'])

        return images[:max_images]

    except Exception as e:
        print(f"Wikimedia error: {str(e)}")
        return []


def get_lq_images_from_google(name: str, max_images: int) -> List[str]:
    """Fallback to lower quality images when needed"""
    try:
        search_term = f"{name} outfit fashion"
        url = f"https://www.google.com/search?q={quote_plus(search_term)}&tbm=isch"

        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }

        response = requests.get(url, headers=headers)
        response.raise_for_status()

        soup = BeautifulSoup(response.text, 'html.parser')
        images = []

        for img in soup.find_all('img', limit=max_images * 2):  # Get extra to account for non-image elements
            img_url = img.get('src')
            if img_url and img_url.startswith('http'):
                images.append(img_url)

        return images[:max_images]

    except Exception as e:
        print(f"Google LQ images error: {str(e)}")
        return []


@router.post("/crawl-celebrity-quality",
             status_code=status.HTTP_200_OK,
             response_model=List[ImageResponse])
async def crawl_celebrity_images_with_fallback(
        request: CelebrityCrawlRequest,
        db: Annotated[Session, Depends(db.get_db)]
):
    """
    Crawl celebrity images with quality fallback:
    1. First try professional HQ sources
    2. Then try Google large images
    3. Then try Wikimedia
    4. Finally fallback to lower quality
    Returns images with quality metadata
    """
    try:
        # Try HQ sources in order of preference
        hq_sources = [
            get_hq_images_from_professional_sources,
            get_hq_images_from_google,
            get_images_from_wikimedia
        ]

        all_urls = []
        hq_urls = []
        lq_urls = []

        # First pass: collect all potential URLs
        for source in hq_sources:
            if len(all_urls) < request.max_images * 3:  # Collect more than needed for verification
                try:
                    new_urls = source(request.name, request.max_images * 2)
                    all_urls.extend(new_urls)
                except Exception as e:
                    print(f"Error with {source.__name__}: {str(e)}")
                    continue

        # Verify image quality
        for url in all_urls:
            if len(hq_urls) >= request.max_images and len(lq_urls) >= request.max_images:
                break

            try:
                is_hq, width, height = verify_image_resolution(url)
                if is_hq and len(hq_urls) < request.max_images:
                    hq_urls.append((url, width, height))
                elif not is_hq and len(lq_urls) < request.max_images:
                    lq_urls.append((url, width, height))
            except Exception as e:
                print(f"Error verifying {url}: {str(e)}")
                continue

        # If we don't have enough HQ, get some LQ as fallback
        if len(hq_urls) < request.max_images and not request.require_hq:
            needed = request.max_images - len(hq_urls)
            lq_fallback = get_lq_images_from_google(request.name, needed)
            for url in lq_fallback:
                try:
                    is_hq, width, height = verify_image_resolution(url)
                    if not is_hq:
                        lq_urls.append((url, width, height))
                except Exception:
                    continue

        # Combine results (HQ first, then LQ)
        combined = hq_urls + lq_urls[:request.max_images - len(hq_urls)]

        if not combined and request.require_hq:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No high-quality images found for this celebrity"
            )
        elif not combined:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No images found for this celebrity"
            )

        # Store and return results
        results = []
        for img_data in combined[:request.max_images]:
            url, width, height = img_data
            is_hq = width >= HQ_MIN_WIDTH and height >= HQ_MIN_HEIGHT if width and height else False

            # Create filename
            quality_prefix = "hq_" if is_hq else "lq_"
            filename = f"{quality_prefix}{request.name.replace(' ', '_')}_{random.randint(1000, 9999)}.jpg"

            # Store in database
            db_image = models.CelebrityImage(
                original_filename=filename,
                image_url=url,
                source="quality_crawl",
                celebrity_name=request.name,
                crawl_date=datetime.utcnow(),
            )
            db.add(db_image)
            db.commit()
            db.refresh(db_image)

            results.append({
                "id": db_image.id,
                "imgur_url": db_image.image_url,
                "upload_date": db_image.crawl_date,
                "is_hq": is_hq,
                "width": width,
                "height": height
            })

        return results

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error crawling images: {str(e)}"
        )


@router.get("/celebrity/quality",
            status_code=status.HTTP_200_OK,
            response_model=List[ImageResponse])
async def get_celebrity_images_with_quality(
        db: Annotated[Session, Depends(db.get_db)],
        celebrity_name: Optional[str] = None,
        min_quality: Optional[str] = None  # 'hq' or 'any'
):
    """
    Get celebrity images with quality filter
    - min_quality='hq': only returns HQ images
    - min_quality='any': returns all images (default)
    """
    try:
        query = select(CelebrityImage)
        if celebrity_name:
            query = query.where(CelebrityImage.celebrity_name == celebrity_name)
        if min_quality == 'hq':
            query = query.where(CelebrityImage.is_high_quality == True)

        images = db.exec(query.order_by(CelebrityImage.crawl_date.desc())).all()

        return [{
            "id": img.id,
            "imgur_url": img.image_url,
            "upload_date": img.crawl_date,
            "is_hq": img.is_high_quality,
            "width": img.width,
            "height": img.height
        } for img in images]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving images: {str(e)}"
        )