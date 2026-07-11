"""
POST /verify
Called by Flutter when user scans a medicine image.
Persists a Scan row (server-authoritative history + analytics source) and
returns the verification result, including the new scan_id so the client can
link a report to it.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from domain.schemas import VerifyResponse
from services.verification_service import verify_image
from infra.db import get_db
from infra.orm import Scan

router = APIRouter(prefix="/verify", tags=["Verification"])


@router.post("", response_model=VerifyResponse)
async def verify(
    image: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    # Accept image/* and the generic octet-stream / missing type that some
    # mobile pickers send; reject only clearly non-image types. The vision
    # engine is the real gate (it flags non-medicine images as not_medicine).
    ct = (image.content_type or "").lower()
    if ct and not (ct.startswith("image/") or ct == "application/octet-stream"):
        raise HTTPException(status_code=400, detail="File must be an image (jpeg, png, webp).")

    # Guard against absurdly large uploads (10 MB)
    MAX_SIZE = 10 * 1024 * 1024
    contents = await image.read()
    if len(contents) > MAX_SIZE:
        raise HTTPException(status_code=413, detail="Image too large. Max 10 MB.")

    result = await verify_image(contents, image.filename or "image.jpg", db)

    # Persist the scan. medicine_info is None for not_medicine results.
    info = result.medicine_info
    scan = Scan(
        medicine_name=info.name if info else "",
        manufacturer=info.manufacturer if info else "",
        batch_number=info.batch_number if info else "",
        expiry_date=info.expiry_date if info else "",
        status=result.status,
        confidence_score=result.confidence_score,
        notes=result.message,
    )
    db.add(scan)
    await db.flush()          # assigns scan.id before the request-scoped commit
    result.scan_id = scan.id
    return result
