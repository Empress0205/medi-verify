"""
Verification use-case.

Orchestrates: pick engine (config) -> engine.verify(image) -> persist a Scan row
-> return the result. This is where the currently-dead `scans` table finally
gets written (Decision 2: server-authoritative history depends on this).

STATUS: SCAFFOLD ONLY.
"""
from __future__ import annotations
# from infra.engine import inprocess, remote, mock
# from infra.repositories import ScanRepository
