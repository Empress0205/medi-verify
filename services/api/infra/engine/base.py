"""
Verification engine port (the stable seam).

An engine's ONLY job is to read packaging photos into structured fields. It does
NOT decide registered/not_found — that's the matcher's job against the TMDA
`medicines` table. This keeps the swappable AI part separate from the
deterministic register logic.

An engine takes a LIST of photos, because a medicine's identifying information
is routinely split across panels: the brand is on the front, while the
registration number and the expiry are often on the back, the side or the
blister foil. The engine reads them together and returns ONE combined field
set — the images are sent in a single request, so N photos still cost one call.

Implementations (selected by config.ENGINE):
  - gemini.GeminiEngine : Google Gemini vision (free tier)
  - mock.MockEngine     : deterministic fake, no key/network needed
"""
from __future__ import annotations
from typing import Protocol, Sequence

from domain.schemas import ExtractedFields

# An image and the filename it arrived under (used only to infer its MIME type).
Photo = tuple[bytes, str]

# Hard cap on photos per scan — bounds cost and stops an endless capture loop.
MAX_PHOTOS = 3


class VerificationEngine(Protocol):
    async def extract(self, photos: Sequence[Photo]) -> ExtractedFields:
        """Read one or more photos of the SAME pack into one field set."""
        ...
