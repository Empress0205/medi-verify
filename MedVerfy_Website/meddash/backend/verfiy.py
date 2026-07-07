"""
POST /verify
Called by Flutter when user scans a medicine image.
Returns verification result that Flutter maps to ScanRecord.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from schema import VerifyResponse
from verification import verify_medicine_image

router = APIRouter(prefix="/verify", tags=["Verification"])


@router.post("", response_model=VerifyResponse)
async def verify(image: UploadFile = File(...)):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image (jpeg, png, webp).")

    # Guard against absurdly large uploads (10 MB)
    MAX_SIZE = 10 * 1024 * 1024
    contents = await image.read()
    if len(contents) > MAX_SIZE:
        raise HTTPException(status_code=413, detail="Image too large. Max 10 MB.")

    # Reset so verification engine can read it again
    await image.seek(0)

    result = await verify_medicine_image(image)
    return result