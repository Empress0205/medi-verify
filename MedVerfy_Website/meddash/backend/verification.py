"""
Medicine verification engine.

Right now it runs a mock AI that returns plausible results so you can test
the full Flutter → backend → dashboard flow without a real model.

To plug in a real AI model:
  1. Set USE_REAL_AI=true in your .env
  2. Set AI_ENDPOINT and AI_API_KEY
  3. The _call_real_ai() function sends the image as multipart and expects
     the same VerifyResponse JSON shape back.
"""

import random
import hashlib
from datetime import datetime, timedelta
from fastapi import UploadFile
import httpx

from config import get_settings
from schema import VerifyResponse, MedicineInfo

settings = get_settings()

# Seed database of known medicines for the mock engine
MEDICINE_DB = [
    {"name": "Paracetamol 500mg",    "manufacturer": "Dawa Ltd",        "ingredient": "Paracetamol",  "dosage": "500mg"},
    {"name": "Augmentin 625mg",      "manufacturer": "GSK",             "ingredient": "Amoxicillin/Clavulanate", "dosage": "625mg"},
    {"name": "Amoxicillin 250mg",    "manufacturer": "Shelys",          "ingredient": "Amoxicillin",  "dosage": "250mg"},
    {"name": "Amoxicillin 500mg",    "manufacturer": "GSK",             "ingredient": "Amoxicillin",  "dosage": "500mg"},
    {"name": "Metformin 500mg",      "manufacturer": "Universal Corp",  "ingredient": "Metformin HCl","dosage": "500mg"},
    {"name": "Coartem 80/480mg",     "manufacturer": "Novartis",        "ingredient": "Artemether/Lumefantrine", "dosage": "80/480mg"},
    {"name": "Metronidazole 200mg",  "manufacturer": "Dawa Ltd",        "ingredient": "Metronidazole","dosage": "200mg"},
    {"name": "Omeprazole 20mg",      "manufacturer": "Shelys",          "ingredient": "Omeprazole",   "dosage": "20mg"},
    {"name": "Doxycycline 100mg",    "manufacturer": "Universal Corp",  "ingredient": "Doxycycline",  "dosage": "100mg"},
    {"name": "Ibuprofen 400mg",      "manufacturer": "Dawa Ltd",        "ingredient": "Ibuprofen",    "dosage": "400mg"},
    {"name": "Atorvastatin 10mg",    "manufacturer": "Cipla",           "ingredient": "Atorvastatin", "dosage": "10mg"},
    {"name": "Ciprofloxacin 500mg",  "manufacturer": "Shelys",          "ingredient": "Ciprofloxacin","dosage": "500mg"},
]


def _image_hash_seed(image_bytes: bytes) -> int:
    """Derive a deterministic seed from the image so same image → same result."""
    return int(hashlib.md5(image_bytes[:2048]).hexdigest(), 16) % (2**31)


def _random_batch() -> str:
    y = random.randint(2023, 2024)
    n = random.randint(100, 999)
    return f"BN-{y}-0{n}"


def _random_expiry() -> str:
    months_ahead = random.randint(6, 36)
    d = datetime.utcnow() + timedelta(days=months_ahead * 30)
    return d.strftime("%Y-%m")


async def _call_real_ai(image_bytes: bytes, filename: str) -> VerifyResponse:
    """Send image to external AI endpoint and return its response."""
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            settings.AI_ENDPOINT,
            headers={"Authorization": f"Bearer {settings.AI_API_KEY}"},
            files={"image": (filename, image_bytes, "image/jpeg")},
        )
        resp.raise_for_status()
        return VerifyResponse(**resp.json())


async def _mock_ai(image_bytes: bytes) -> VerifyResponse:
    """
    Deterministic mock: same image always gives the same result.
    Simulates ~70% verified, ~20% counterfeit, ~10% non-medicine.
    """
    seed = _image_hash_seed(image_bytes)
    rng = random.Random(seed)

    roll = rng.random()

    # ~10% chance — not a medicine image
    if roll < 0.10:
        return VerifyResponse(
            success=True,
            status="invalid",
            confidence_score=round(rng.uniform(20, 45), 1),
            message="No medicine packaging detected in the image.",
        )

    # Pick a random medicine from the DB
    med = rng.choice(MEDICINE_DB)
    confidence = round(rng.uniform(72, 99), 1)
    batch = _random_batch()
    expiry = _random_expiry()
    scan_time = datetime.utcnow().isoformat() + "Z"

    info = MedicineInfo(
        name=med["name"],
        manufacturer=med["manufacturer"],
        batch_number=batch,
        expiry_date=expiry,
        scan_time=scan_time,
        active_ingredient=med["ingredient"],
        dosage=med["dosage"],
        warnings=["Store below 30°C", "Keep out of reach of children"] if rng.random() > 0.6 else None,
    )

    # ~20% counterfeit (of medicine images)
    if roll < 0.30:
        return VerifyResponse(
            success=True,
            status="counterfeit",
            confidence_score=confidence,
            medicine_info=info,
            message="Packaging inconsistencies detected. Likely counterfeit.",
        )

    # 70% verified
    return VerifyResponse(
        success=True,
        status="verified",
        confidence_score=confidence,
        medicine_info=info,
        message="Medicine verified against database records.",
    )


async def verify_medicine_image(file: UploadFile) -> VerifyResponse:
    """Entry point called by the router."""
    image_bytes = await file.read()

    if settings.USE_REAL_AI and settings.AI_ENDPOINT:
        return await _call_real_ai(image_bytes, file.filename or "image.jpg")
    else:
        return await _mock_ai(image_bytes)