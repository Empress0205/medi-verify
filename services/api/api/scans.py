"""
Scan history router (public / app-scoped).

  GET /scans/{id}         -> single scan result
  GET /scans?device=...   -> a device's history (Decision 2: server-authoritative)

Only needed if history is server-authoritative. If history stays local-first on
the device, this router can be dropped.

STATUS: SCAFFOLD ONLY.
"""
from __future__ import annotations
from fastapi import APIRouter

router = APIRouter(prefix="/scans", tags=["Scans"])
