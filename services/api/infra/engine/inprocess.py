"""
In-process verification engine — real OCR + LLM + TMDA matching.

Wraps the ported modules in this package:
    ocr.py          -> PaddleOCR text extraction
    llm.py          -> Ollama (llama3.2) field extraction
    matcher.py      -> fuzzy match against the TMDA `medicines` table
    tmda_loader.py  -> CSV import (fix skiprows=2 during import to DB)

STATUS: SCAFFOLD ONLY. Wiring is deferred until Decision 1 (engine deployment)
is made. The pipeline logic currently lives in legacy/backend1/main.py and must
be ported here as a class implementing base.VerificationEngine.
"""
from __future__ import annotations

# from .base import VerificationEngine
# from . import ocr, llm, matcher


class InProcessEngine:  # implements base.VerificationEngine
    async def verify(self, image_bytes: bytes, filename: str):
        raise NotImplementedError(
            "Port the OCR->LLM->match pipeline from legacy/backend1/main.py here."
        )
