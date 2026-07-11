"""
Gemini vision engine — reads a packaging photo into structured fields.

Uses Google's Generative Language REST API (free tier). No SDK dependency:
one httpx call with the image inline as base64. The model is asked to return
strict JSON matching ExtractedFields.
"""
from __future__ import annotations
import asyncio
import base64
import json

import httpx

from config import get_settings
from domain.schemas import ExtractedFields

settings = get_settings()

_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"

_PROMPT = """You are reading a photo of medicine packaging from Tanzania.

First decide: is this actually a photo of medicine/drug packaging (a box, blister
strip, bottle or label)? Set "is_medicine" false if it is anything else (a person,
food, a random object, an unreadable blur).

If it IS medicine packaging, read these fields exactly as printed. Do not guess or
translate. Use null for any field that is not visible.

Return ONLY this JSON object:
{
  "is_medicine": true,
  "medicine_name": "brand or product name",
  "strength": "e.g. 500mg",
  "reg_no": "TMDA/TFDA registration or certificate number if shown",
  "batch_number": "batch / lot number",
  "mfg_date": "manufacture date as printed",
  "expiry_date": "expiry date as printed",
  "manufacturer": "manufacturer or marketing company"
}"""


class GeminiEngine:
    def __init__(self) -> None:
        self.api_key = settings.GEMINI_API_KEY.strip()
        self.model = settings.GEMINI_MODEL or "gemini-flash-latest"

    async def extract(self, image_bytes: bytes, filename: str) -> ExtractedFields:
        if not self.api_key:
            raise RuntimeError("GEMINI_API_KEY is not set")

        b64 = base64.b64encode(image_bytes).decode()
        mime = "image/png" if filename.lower().endswith(".png") else "image/jpeg"
        body = {
            "contents": [{"parts": [
                {"text": _PROMPT},
                {"inline_data": {"mime_type": mime, "data": b64}},
            ]}],
            "generationConfig": {"temperature": 0, "responseMimeType": "application/json"},
        }
        url = _ENDPOINT.format(model=self.model)
        headers = {"x-goog-api-key": self.api_key}  # key in header, not the URL
        data = await self._post_with_retry(url, headers, body)

        text = data["candidates"][0]["content"]["parts"][0]["text"]
        raw = _first_json_object(text)
        return ExtractedFields(
            is_medicine=bool(raw.get("is_medicine", True)),
            medicine_name=_s(raw.get("medicine_name")),
            strength=_s(raw.get("strength")),
            reg_no=_s(raw.get("reg_no")),
            batch_number=_s(raw.get("batch_number")),
            mfg_date=_s(raw.get("mfg_date")),
            expiry_date=_s(raw.get("expiry_date")),
            manufacturer=_s(raw.get("manufacturer")),
        )


    async def _post_with_retry(self, url, headers, body, attempts: int = 3) -> dict:
        """Retry transient overload/rate errors (429/5xx) with short backoff."""
        transient = {429, 500, 502, 503, 504}
        async with httpx.AsyncClient(timeout=60) as client:
            for i in range(attempts):
                r = await client.post(url, headers=headers, json=body)
                if r.status_code in transient and i < attempts - 1:
                    await asyncio.sleep(1.5 * (i + 1))
                    continue
                r.raise_for_status()
                return r.json()


def _first_json_object(text: str) -> dict:
    """Decode the first JSON object in the response, ignoring any trailing text
    or extra objects the model may append."""
    i = text.find("{")
    if i < 0:
        raise ValueError("no JSON object in model response")
    obj, _ = json.JSONDecoder().raw_decode(text[i:])
    return obj


def _s(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None
