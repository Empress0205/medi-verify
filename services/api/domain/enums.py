"""
Canonical domain enums — the SINGLE source of truth for status values.

Flutter (VerificationStatus) and the React dashboard must mirror these exact
string values. `orm.py` and `schemas.py` should import from here instead of
redefining their own copies (wiring TODO).
"""
from __future__ import annotations
import enum


class ScanStatus(str, enum.Enum):
    verified = "verified"
    counterfeit = "counterfeit"
    unknown = "unknown"
    not_medicine = "not_medicine"


class ReportStatus(str, enum.Enum):
    pending = "pending"
    under_review = "under_review"
    confirmed = "confirmed"
    dismissed = "dismissed"


# Confidence is canonical as a 0.0–1.0 float everywhere (DB, API).
# Format to a percentage ONLY at the UI edge. See docs/ARCHITECTURE.md.
CONFIDENCE_MIN = 0.0
CONFIDENCE_MAX = 1.0
