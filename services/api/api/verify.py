"""
POST /verify
Called by Flutter when a user scans a medicine.

Accepts ONE OR MORE photos of the same pack. A medicine's identifying details
are routinely split across panels (brand on the front; registration number and
expiry on the back or blister foil), so the client may send a second photo after
we tell it something decisive is missing. All photos go to the vision engine in
a single request and are read as one product.

Persists a Scan row (server-authoritative history + analytics source) and
returns the result, including scan_id so the client can link a report to it.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from domain.schemas import VerifyResponse
from services.verification_service import verify_image
from infra.db import get_db
from infra.engine.base import MAX_PHOTOS, Photo
from infra.orm import Scan

router = APIRouter(prefix="/verify", tags=["Verification"])

MAX_SIZE = 10 * 1024 * 1024  # 10 MB per photo


def _check_type(upload: UploadFile) -> None:
    # Accept image/* and the generic octet-stream / missing type that some mobile
    # pickers send; reject only clearly non-image types. The vision engine is the
    # real gate (it flags non-medicine images as not_medicine).
    ct = (upload.content_type or "").lower()
    if ct and not (ct.startswith("image/") or ct == "application/octet-stream"):
        raise HTTPException(
            status_code=400, detail="File must be an image (jpeg, png, webp)."
        )


@router.post("", response_model=VerifyResponse)
async def verify(
    # `image` is the original single-photo field, kept so older clients keep
    # working; `images` is the multi-panel form. (A plain list default is
    # required here — `list[UploadFile] | None` makes FastAPI bind a single
    # file instead of collecting the repeated parts.)
    image: UploadFile | None = File(None),
    images: list[UploadFile] = File([]),
    db: AsyncSession = Depends(get_db),
):
    uploads = [u for u in ([image] if image else []) + list(images) if u is not None]
    if not uploads:
        raise HTTPException(status_code=422, detail="Send at least one image.")
    if len(uploads) > MAX_PHOTOS:
        raise HTTPException(
            status_code=400, detail=f"Send at most {MAX_PHOTOS} photos of the pack."
        )

    photos: list[Photo] = []
    for upload in uploads:
        _check_type(upload)
        contents = await upload.read()
        if len(contents) > MAX_SIZE:
            raise HTTPException(status_code=413, detail="Image too large. Max 10 MB.")
        photos.append((contents, upload.filename or "image.jpg"))

    result = await verify_image(photos, db)

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
