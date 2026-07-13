"""
Verification use-case — orchestrates: pick engine (config) -> extract fields
from the photos -> match against the TMDA register -> VerifyResponse.

The engine (vision AI) and the matcher (register lookup) are separate on
purpose: the AI only reads the label; the deterministic matcher decides
registered / not_found.

A scan may carry SEVERAL photos of the same pack. A medicine's identifying
information is routinely split across panels — the brand on the front, the
registration number and the expiry on the back or the blister foil — so one
photo of the front often misses the two fields that matter most. When something
decisive is still missing we hand the app a CaptureHint asking for another
photo, rather than silently returning a worse answer.
"""
from __future__ import annotations
from functools import lru_cache
from typing import Sequence

from sqlalchemy.ext.asyncio import AsyncSession

from config import get_settings
from domain.enums import ExpiryStatus, ScanStatus
from domain.schemas import CaptureHint, VerifyResponse
from infra.engine import matcher
from infra.engine.base import MAX_PHOTOS, Photo


@lru_cache
def get_engine():
    name = get_settings().ENGINE.strip().lower()
    if name == "gemini":
        from infra.engine.gemini import GeminiEngine
        return GeminiEngine()
    from infra.engine.mock import MockEngine
    return MockEngine()


async def verify_image(photos: Sequence[Photo], db: AsyncSession) -> VerifyResponse:
    engine = get_engine()
    photos = list(photos)[:MAX_PHOTOS]

    try:
        fields = await engine.extract(photos)
    except Exception as e:
        # Never leak a stack trace to the user; degrade gracefully.
        return VerifyResponse(
            success=False, status=ScanStatus.unknown, confidence_score=0.0,
            message="The verification service is temporarily unavailable. Please try again shortly.",
            error_message=str(e)[:300],
        )

    # Guardrail: never stitch fields from two DIFFERENT products into one match.
    if fields.conflict:
        return VerifyResponse(
            success=True, status=ScanStatus.unknown, confidence_score=0.0,
            message="These photos look like different products. Please photograph "
                    "only one medicine at a time — the same pack from different sides.",
        )

    result = await matcher.match(fields, db)
    result.capture = _capture_hint(result, fields, len(photos))
    return result


# A name-only match at or above this confidence is treated as settled; below it,
# the registration number would still materially firm the answer up.
_CONFIDENT_MATCH = 0.90


def _capture_hint(result: VerifyResponse, fields, photo_count: int) -> CaptureHint:
    """Would another photo of this pack materially improve the answer?

    Only ask when the extra photo could actually change something:

      * the expiry date — safety-critical, usually on another panel, and the one
        field that can hurt the user. A clean register match is NOT grounds to
        stop asking: we may still be blind to the expiry.
      * the registration number — decisive for an authoritative match, but only
        worth chasing when the match is still weak or missing. Once the product
        is confidently matched there is nothing more for it to prove, and asking
        again would be pure friction.
    """
    if result.status is ScanStatus.not_medicine or photo_count >= MAX_PHOTOS:
        return CaptureHint(needs_more=False)

    missing: list[str] = []

    unmatched = result.status in (ScanStatus.not_found, ScanStatus.unknown)
    weak_match = result.confidence_score < _CONFIDENT_MATCH
    if not fields.reg_no and (unmatched or weak_match):
        missing.append("registration number")

    if result.safety is None or result.safety.expiry_status is ExpiryStatus.unknown:
        missing.append("expiry date")

    if not missing:
        return CaptureHint(needs_more=False)

    what = " and ".join(missing)
    return CaptureHint(
        needs_more=True,
        missing=missing,
        prompt=(
            f"We couldn't find the {what} on this side of the pack. "
            "Photograph another part of the SAME pack — the back or side panel, "
            "or the blister strip — and we'll check again."
        ),
    )
