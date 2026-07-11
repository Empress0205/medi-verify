"""Text normalization shared by the register sync and the matcher.

The whole point: a certificate number read off a photo ("TAN 22 HM 0470")
must compare equal to the register's stored form ("TAN  22  HM  0470") and to
lowercase/space variants. So we strip to bare uppercase alphanumerics.
"""
import re


def normalize_cert(value) -> str:
    """'TAN  22  HM  0470' / 'tan 22 hm 0470' / 'TAN22HM0470' -> 'TAN22HM0470'."""
    if not value:
        return ""
    return re.sub(r"[^A-Z0-9]", "", str(value).upper())


def normalize_name(value) -> str:
    """Lowercase, collapse whitespace — for fuzzy name comparison."""
    if not value:
        return ""
    return re.sub(r"\s+", " ", str(value).strip().lower())
