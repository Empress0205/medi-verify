"""
Canonical domain enums — the SINGLE source of truth for status values.

Flutter (VerificationStatus) and the React dashboard must mirror these exact
string values. `orm.py` and `schemas.py` should import from here instead of
redefining their own copies (wiring TODO).
"""
from __future__ import annotations
import enum


class ScanStatus(str, enum.Enum):
    """Outcome of a REGISTRATION check against the TMDA register.

    The engine verifies that the package text matches a registered product —
    it cannot prove physical authenticity, so there is deliberately no
    "counterfeit" value here. Counterfeit is a human conclusion, reached in
    the dashboard by confirming a report (ReportStatus.confirmed).
    """
    registered = "registered"        # strong match to a TMDA record
    not_found = "not_found"          # readable, but no convincing register match
    unknown = "unknown"              # inconclusive read/match
    not_medicine = "not_medicine"    # image isn't medicine packaging


class ReportStatus(str, enum.Enum):
    pending = "pending"
    under_review = "under_review"
    confirmed = "confirmed"
    dismissed = "dismissed"


# Confidence is canonical as a 0.0–1.0 float everywhere (DB, API).
# Format to a percentage ONLY at the UI edge. See docs/ARCHITECTURE.md.
CONFIDENCE_MIN = 0.0
CONFIDENCE_MAX = 1.0
