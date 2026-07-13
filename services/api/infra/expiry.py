"""
Parsing and classification of the expiry date printed on a medicine pack.

Two rules drive everything here:

  1. A month-only date ("AUG.2027", "08/2027") means the pack is good through
     the LAST day of that month — so it resolves to 31 Aug 2027, not 1 Aug.
  2. If we cannot read a date confidently we return None → ExpiryStatus.unknown.
     `unknown` must never be presented as "not expired": absence of a reading is
     not evidence of validity.
"""
from __future__ import annotations

import calendar
import re
from datetime import date
from typing import Optional

from domain.enums import ExpiryStatus

# A pack expiring within this window is flagged as "expiring soon".
EXPIRING_SOON_DAYS = 60

_MONTHS = {
    "jan": 1, "january": 1,
    "feb": 2, "february": 2,
    "mar": 3, "march": 3,
    "apr": 4, "april": 4,
    "may": 5,
    "jun": 6, "june": 6,
    "jul": 7, "july": 7,
    "aug": 8, "august": 8,
    "sep": 9, "sept": 9, "september": 9,
    "oct": 10, "october": 10,
    "nov": 11, "november": 11,
    "dec": 12, "december": 12,
}

# Strip label noise like "EXP:", "EXPIRY", "USE BEFORE".
_NOISE = re.compile(
    r"\b(exp(?:iry|ires?|\.)?|use\s*(?:by|before)|best\s*before|date)\b[:.\s]*",
    re.IGNORECASE,
)


def _end_of_month(year: int, month: int) -> date:
    return date(year, month, calendar.monthrange(year, month)[1])


def _year(token: str) -> Optional[int]:
    try:
        y = int(token)
    except (TypeError, ValueError):
        return None
    if y < 100:                 # two-digit year: 27 -> 2027
        y += 2000
    return y if 2000 <= y <= 2100 else None


def parse_expiry(raw: Optional[str]) -> Optional[date]:
    """Best-effort parse of a printed expiry. Returns None if not confident."""
    if not raw:
        return None

    s = _NOISE.sub(" ", str(raw))
    s = s.replace(".", " ").replace(",", " ")
    s = re.sub(r"\s+", " ", s).strip().lower()
    if not s:
        return None

    # 1) Month name + year — "AUG 2027", "AUGUST 27", "AUG-27"
    m = re.search(r"([a-z]{3,9})\s*[-/ ]?\s*(\d{2,4})", s)
    if m and m.group(1) in _MONTHS:
        y = _year(m.group(2))
        if y:
            return _end_of_month(y, _MONTHS[m.group(1)])

    # 2) Year-first — "2027-08-31", "2027/08"
    m = re.search(r"(\d{4})[-/ ](\d{1,2})(?:[-/ ](\d{1,2}))?", s)
    if m:
        y, mo = int(m.group(1)), int(m.group(2))
        if 2000 <= y <= 2100 and 1 <= mo <= 12:
            if m.group(3):
                try:
                    return date(y, mo, int(m.group(3)))
                except ValueError:
                    return _end_of_month(y, mo)
            return _end_of_month(y, mo)

    # 3) Day/month/year or month/year — "31/08/2027", "08/2027", "08/27"
    #    (day-first: the convention in Tanzania, and unambiguous when >12)
    m = re.search(r"(\d{1,2})[-/ ](\d{1,4})(?:[-/ ](\d{2,4}))?", s)
    if m:
        a, b, c = m.group(1), m.group(2), m.group(3)
        if c:
            day, mo, y = int(a), int(b), _year(c)
            if y and 1 <= mo <= 12:
                try:
                    return date(y, mo, day)
                except ValueError:
                    return _end_of_month(y, mo)
        else:
            mo, y = int(a), _year(b)
            if y and 1 <= mo <= 12:
                return _end_of_month(y, mo)

    return None


def classify_expiry(expiry: Optional[date], today: Optional[date] = None) -> ExpiryStatus:
    """Map a parsed expiry to a status. No date read => unknown (never 'valid')."""
    if expiry is None:
        return ExpiryStatus.unknown
    today = today or date.today()
    if expiry < today:
        return ExpiryStatus.expired
    if (expiry - today).days <= EXPIRING_SOON_DAYS:
        return ExpiryStatus.expiring_soon
    return ExpiryStatus.valid


def days_until(expiry: Optional[date], today: Optional[date] = None) -> Optional[int]:
    if expiry is None:
        return None
    return (expiry - (today or date.today())).days
