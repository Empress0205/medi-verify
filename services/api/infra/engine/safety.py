"""
Safety assessment — the layer that sits ON TOP of the registration verdict.

The registration verdict answers "is this product on the TMDA register?".
That is a fact, and expiry never changes it: an expired medicine is still a
*registered* medicine. But answering only that question would let us show a
reassuring green "Registered" badge on a box that expired two years ago —
technically true, and dangerously misleading.

So the result is modelled on two axes:

  * verdict  (registered / not_found / unknown)      — the fact
  * flags    (pack expiry, registration validity)    — the safety layer

The flags never rewrite the verdict; they decide how loudly it is presented.
Severity is calibrated so that `danger` is reserved for facts we actually read
off the pack (an expiry date), never for absence of evidence (a not_found is
uncertainty — it cautions, it does not accuse).
"""
from __future__ import annotations

from datetime import date, datetime
from typing import Optional

from domain.enums import (
    ExpiryStatus,
    RegistrationValidity,
    ScanStatus,
    Severity,
)
from domain.schemas import SafetyInfo
from infra.expiry import classify_expiry, days_until, parse_expiry


def _fmt(d: Optional[date]) -> str:
    return d.strftime("%d %b %Y") if d else ""


def assess(
    status: ScanStatus,
    printed_expiry: Optional[str],
    cert_expiry: Optional[datetime],
    today: Optional[date] = None,
) -> SafetyInfo:
    """Build the safety layer for a verification result."""
    today = today or date.today()

    # ── Axis 2a: the pack in the user's hand ──────────────────────────────────
    exp_date = parse_expiry(printed_expiry)
    exp_status = classify_expiry(exp_date, today)
    exp_days = days_until(exp_date, today)

    # ── Axis 2b: the product's registration certificate ───────────────────────
    if cert_expiry is None:
        reg_validity = RegistrationValidity.unknown
    elif cert_expiry.date() < today:
        reg_validity = RegistrationValidity.lapsed
    else:
        reg_validity = RegistrationValidity.current

    expired = exp_status is ExpiryStatus.expired
    lapsed = reg_validity is RegistrationValidity.lapsed

    severity: Severity
    headline: str
    detail: Optional[str] = None

    # ── The matrix ────────────────────────────────────────────────────────────
    if status is ScanStatus.registered:
        if expired and lapsed:
            severity = Severity.danger
            headline = f"Do not use — this pack expired on {_fmt(exp_date)}"
            detail = ("The product is on the TMDA register, but this box has expired "
                      f"and the product's registration also lapsed on {_fmt(cert_expiry)}.")
        elif expired:
            severity = Severity.danger
            headline = f"Do not use — this pack expired on {_fmt(exp_date)}"
            detail = ("The product itself is registered with TMDA, but this particular "
                      "box is out of date. Do not take it; return it to the pharmacy.")
        elif lapsed:
            severity = Severity.warning
            headline = f"Registration expired on {_fmt(cert_expiry)}"
            detail = ("This product was approved by TMDA, but its registration is no "
                      "longer current. Check with the pharmacy or a pharmacist.")
        elif exp_status is ExpiryStatus.unknown:
            severity = Severity.warning
            headline = "Registered with TMDA — but we couldn't read an expiry date"
            detail = ("Check the expiry printed on the pack yourself before using it. "
                      "You can also photograph the side or back of the pack to try again.")
        elif exp_status is ExpiryStatus.expiring_soon:
            severity = Severity.caution
            headline = f"Registered with TMDA — expires soon ({_fmt(exp_date)})"
            detail = "The product is registered, but this pack is close to its expiry date."
        else:
            severity = Severity.ok
            headline = "Registered with TMDA"
            detail = f"This pack is in date until {_fmt(exp_date)}."

    elif status is ScanStatus.not_found:
        if expired:
            severity = Severity.danger
            headline = f"Do not use — this pack expired on {_fmt(exp_date)}"
            detail = ("We also could not find this product on the TMDA register. "
                      "Do not take it, and please report it.")
        else:
            severity = Severity.warning
            headline = "Not on the TMDA register"
            detail = ("This does not prove it is fake — it may be newly registered, or "
                      "the label may have been misread. Be cautious and report it.")

    elif status is ScanStatus.unknown:
        if expired:
            # We failed the register check, but an expiry we DID read is still a fact.
            severity = Severity.danger
            headline = f"Do not use — this pack expired on {_fmt(exp_date)}"
            detail = ("We could not complete the registration check, but the expiry date "
                      "on this pack has passed.")
        else:
            severity = Severity.unknown
            headline = "We couldn't complete the check"
            detail = "Try again with a clearer, well-lit photo of the label."

    else:  # not_medicine — safety flags do not apply
        severity = Severity.unknown
        headline = "This image does not look like medicine packaging"

    # Anything a user could act on (or that TMDA would want to know about).
    reportable = expired or lapsed or status is ScanStatus.not_found

    return SafetyInfo(
        expiry_status=exp_status,
        expiry_date=exp_date.isoformat() if exp_date else None,
        days_to_expiry=exp_days,
        registration_validity=reg_validity,
        registration_expiry=cert_expiry.date().isoformat() if cert_expiry else None,
        severity=severity,
        headline=headline,
        detail=detail,
        reportable=reportable,
    )
