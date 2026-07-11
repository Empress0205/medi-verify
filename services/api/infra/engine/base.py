"""
Verification engine port (the stable seam).

An engine's ONLY job is to read a packaging photo into structured fields. It
does NOT decide registered/not_found — that's the matcher's job against the
TMDA `medicines` table. This keeps the swappable AI part separate from the
deterministic register logic.

Implementations (selected by config.ENGINE):
  - gemini.GeminiEngine : Google Gemini vision (free tier)
  - groq.GroqEngine     : Groq vision (fallback)   [optional]
  - mock.MockEngine     : deterministic fake, no key/network needed
"""
from __future__ import annotations
from typing import Protocol

from domain.schemas import ExtractedFields


class VerificationEngine(Protocol):
    async def extract(self, image_bytes: bytes, filename: str) -> ExtractedFields:
        """Read the packaging photo into structured fields."""
        ...
