"""
Verification use-case — orchestrates: pick engine (config) -> extract fields
from the photo -> match against the TMDA register -> VerifyResponse.

The engine (vision AI) and the matcher (register lookup) are separate on
purpose: the AI only reads the label; the deterministic matcher decides
registered / not_found.
"""
from __future__ import annotations
from functools import lru_cache

from sqlalchemy.ext.asyncio import AsyncSession

from config import get_settings
from domain.schemas import VerifyResponse
from infra.engine import matcher


@lru_cache
def get_engine():
    name = get_settings().ENGINE.strip().lower()
    if name == "gemini":
        from infra.engine.gemini import GeminiEngine
        return GeminiEngine()
    if name == "groq":
        from infra.engine.groq import GroqEngine
        return GroqEngine()
    from infra.engine.mock import MockEngine
    return MockEngine()


async def verify_image(image_bytes: bytes, filename: str, db: AsyncSession) -> VerifyResponse:
    engine = get_engine()
    try:
        fields = await engine.extract(image_bytes, filename)
    except Exception as e:
        # Never leak a stack trace to the user; degrade gracefully.
        return VerifyResponse(
            success=False, status="unknown", confidence_score=0.0,
            message="The verification service is temporarily unavailable. Please try again shortly.",
            error_message=str(e)[:300],
        )
    return await matcher.match(fields, db)
