"""
Analytics use-case: aggregate scans + reports into dashboard figures.

Move the aggregation now living inline in api/analytics.py here. Also fix the
6-month trend bucketing (key by year-month, not month abbreviation).

STATUS: SCAFFOLD ONLY.
"""
from __future__ import annotations
