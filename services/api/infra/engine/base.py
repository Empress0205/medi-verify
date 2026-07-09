"""
Verification engine port (the stable seam).

The API depends only on this Protocol. Concrete implementations:
  - inprocess.InProcessEngine : runs PaddleOCR + Ollama + TMDA matcher locally
  - remote.RemoteEngine       : calls a separate inference service over HTTP
  - mock.py                   : deterministic fake for dev/demo/CI

Which one is used is chosen by config (Decision 1: engine deployment).
"""
from __future__ import annotations
from typing import Protocol

from domain.schemas import VerifyResponse


class VerificationEngine(Protocol):
    async def verify(self, image_bytes: bytes, filename: str) -> VerifyResponse:
        """Take raw image bytes, return a verification result."""
        ...
