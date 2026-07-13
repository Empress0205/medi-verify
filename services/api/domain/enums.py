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


class ExpiryStatus(str, enum.Enum):
    """Validity of the PACK in the user's hand, read off the printed label.

    Independent of registration: a properly registered product can still be an
    expired box on the shelf. `unknown` means we could not read a date — it must
    NEVER be treated as "not expired".
    """
    valid = "valid"
    expiring_soon = "expiring_soon"
    expired = "expired"
    unknown = "unknown"


class RegistrationValidity(str, enum.Enum):
    """Validity of the PRODUCT'S TMDA registration certificate itself.

    Distinct from pack expiry — this is a regulatory status, not a safety date.
    """
    current = "current"
    lapsed = "lapsed"
    unknown = "unknown"


class Severity(str, enum.Enum):
    """How the result should be presented. Deliberately calibrated:

    `danger` is reserved for FACTS we are sure of (an expiry date we actually
    read off the pack), never for absence of evidence — a not_found is
    uncertainty, so it warns but does not scream.
    """
    ok = "ok"            # green  — registered, current, in date
    caution = "caution"  # amber-lite — registered but expiring soon
    warning = "warning"  # amber  — not on register / lapsed / expiry unreadable
    danger = "danger"    # red    — expired pack: do not use
    unknown = "unknown"  # grey   — check could not be completed


class ReportStatus(str, enum.Enum):
    pending = "pending"
    under_review = "under_review"
    confirmed = "confirmed"
    dismissed = "dismissed"


# Confidence is canonical as a 0.0–1.0 float everywhere (DB, API).
# Format to a percentage ONLY at the UI edge. See docs/ARCHITECTURE.md.
CONFIDENCE_MIN = 0.0
CONFIDENCE_MAX = 1.0
