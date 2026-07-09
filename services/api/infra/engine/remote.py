"""
Remote verification engine — calls a separate inference service over HTTP.

Use this when the OCR/LLM engine runs as its own deployment (services/inference/,
e.g. on a GPU box). Mirrors the seam already sketched in mock.py's `_call_real_ai`.

STATUS: SCAFFOLD ONLY. Enabled by config when Decision 1 selects the split model.
"""
from __future__ import annotations
# import httpx
# from config import get_settings
# from domain.schemas import VerifyResponse


class RemoteEngine:  # implements base.VerificationEngine
    async def verify(self, image_bytes: bytes, filename: str):
        raise NotImplementedError(
            "POST image to settings.AI_ENDPOINT and parse VerifyResponse back."
        )
