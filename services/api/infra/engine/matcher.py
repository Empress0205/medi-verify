"""
Register matcher — turns extracted packaging fields into a verification result
by looking them up in the local TMDA `medicines` table.

Decision policy (deliberately asymmetric — see docs, decision #1):
  * Only claim REGISTERED on strong evidence (exact reg-number, or a strong
    name match). A false "registered" reassures a victim, so we bias against it.
  * Anything weaker is NOT_FOUND — "we couldn't find it, be cautious" — never an
    accusation of counterfeit.
  * We surface the matched record (incl. what the genuine product looks like and
    whether the registration itself is still valid) as evidence.
"""
from __future__ import annotations
import re
from datetime import datetime
from difflib import SequenceMatcher
from typing import Optional

from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from domain.enums import ScanStatus
from domain.schemas import ExtractedFields, VerifyResponse, MedicineInfo
from infra.orm import Medicine
from infra.normalize import normalize_cert, normalize_name

# Below this name-similarity we will NOT claim "registered".
REGISTERED_MIN_NAME = 0.82


async def match(fields: ExtractedFields, db: AsyncSession) -> VerifyResponse:
    scan_time = datetime.utcnow().isoformat() + "Z"

    if not fields.is_medicine:
        return VerifyResponse(
            success=True, status=ScanStatus.not_medicine, confidence_score=0.0,
            message="This image does not look like medicine packaging. "
                    "Please photograph the medicine's box, strip or label.",
        )

    name = fields.medicine_name
    reg = fields.reg_no
    if not name and not reg:
        return VerifyResponse(
            success=True, status=ScanStatus.unknown, confidence_score=0.0,
            message="We couldn't read a medicine name or registration number. "
                    "Try again with a clearer, well-lit photo of the label.",
        )

    # ── Strategy 1: registration number (normalized, exact then partial) ──────
    reg_norm = normalize_cert(reg)
    if reg_norm and len(reg_norm) >= 6:
        hit = (await db.execute(
            select(Medicine).where(Medicine.cert_no_norm == reg_norm)
        )).scalars().first()
        if hit:
            return _registered(hit, fields, scan_time, 0.97, "Registration number (exact)")

        hit = (await db.execute(
            select(Medicine).where(Medicine.cert_no_norm.like(f"%{reg_norm}%"))
        )).scalars().first()
        if hit:
            return _registered(hit, fields, scan_time, 0.90, "Registration number (partial)")

    # ── Strategy 2: name (+ manufacturer) fuzzy ───────────────────────────────
    if name:
        best, score, method = await _best_name_match(name, fields.manufacturer, db)
        if best is not None and score >= REGISTERED_MIN_NAME:
            conf = min(0.93, 0.55 + score * 0.4)
            return _registered(best, fields, scan_time, conf, method)

    return _not_found(fields, scan_time)


# ── helpers ────────────────────────────────────────────────────────────────────

def _ratio(a: str, b: str) -> float:
    if not a or not b:
        return 0.0
    return SequenceMatcher(None, a, b).ratio()


def _contains(a: str, b: str) -> float:
    """High score when one normalized name contains the other (>=4 chars)."""
    if not a or not b:
        return 0.0
    short, long = (a, b) if len(a) <= len(b) else (b, a)
    return 0.9 if len(short) >= 4 and short in long else 0.0


async def _best_name_match(name: str, manufacturer: Optional[str], db: AsyncSession):
    nn = normalize_name(name)
    tokens = [t for t in re.split(r"[^a-z0-9]+", nn) if len(t) >= 3 and not t.isdigit()]
    if not tokens:
        return None, 0.0, ""

    # Prefilter: candidates sharing a significant token in brand or generic name.
    conds = []
    for t in tokens[:3]:
        conds.append(Medicine.brand_name.ilike(f"%{t}%"))
        conds.append(Medicine.generic_name.ilike(f"%{t}%"))
    candidates = (await db.execute(
        select(Medicine).where(or_(*conds)).limit(500)
    )).scalars().all()

    mnorm = normalize_name(manufacturer) if manufacturer else ""
    best, best_score, method = None, 0.0, ""
    for m in candidates:
        b = normalize_name(m.brand_name or "")
        g = normalize_name(m.generic_name or "")
        s = max(_ratio(nn, b), _ratio(nn, g), _contains(nn, b), _contains(nn, g))
        used_mfr = False
        if mnorm and m.manufacturer and _ratio(mnorm, normalize_name(m.manufacturer)) > 0.6:
            s = min(1.0, s + 0.05)  # small boost when the manufacturer agrees too
            used_mfr = True
        if s > best_score:
            best, best_score = m, s
            method = "Name + manufacturer" if used_mfr else "Medicine name"
    return best, best_score, method


def _registered(m: Medicine, fields: ExtractedFields, scan_time: str,
                confidence: float, method: str) -> VerifyResponse:
    lapsed = m.cert_expiry_date is not None and m.cert_expiry_date < datetime.utcnow()
    if lapsed:
        msg = (f"Matches a TMDA record ({method}), but the product's registration "
               f"appears to have expired on {m.cert_expiry_date:%d %b %Y}. Check with the pharmacy.")
    else:
        msg = f"This product matches a registered TMDA record ({method})."

    info = MedicineInfo(
        name=m.brand_name or fields.medicine_name or "Unknown",
        manufacturer=m.manufacturer or fields.manufacturer or "Unknown",
        batch_number=fields.batch_number or "Not on label",
        manufacture_date=fields.mfg_date,
        expiry_date=fields.expiry_date or "Not on label",
        scan_time=scan_time,
        active_ingredient=m.generic_name or m.active_ingredient,
        dosage=m.strength or fields.strength,
        description=m.physical_description,
        reg_no=m.certificate_no,
        registration_status=m.registration_status,
        registration_expiry=(m.cert_expiry_date.strftime("%Y-%m-%d") if m.cert_expiry_date else None),
        physical_description=m.physical_description,
    )
    return VerifyResponse(
        success=True, status=ScanStatus.registered,
        confidence_score=round(confidence, 3), medicine_info=info, message=msg,
    )


def _not_found(fields: ExtractedFields, scan_time: str) -> VerifyResponse:
    info = MedicineInfo(
        name=fields.medicine_name or "Unknown",
        manufacturer=fields.manufacturer or "Unknown",
        batch_number=fields.batch_number or "Not on label",
        manufacture_date=fields.mfg_date,
        expiry_date=fields.expiry_date or "Not on label",
        scan_time=scan_time,
        dosage=fields.strength,
        reg_no=fields.reg_no,
    )
    return VerifyResponse(
        success=True, status=ScanStatus.not_found, confidence_score=0.2,
        medicine_info=info,
        message="We could not find this product on the TMDA register. This does not "
                "prove it is fake — it may be newly registered or the label may have been "
                "misread. Be cautious, and please report it so TMDA can review.",
    )
