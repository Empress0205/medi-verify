"""
Report use-case: create report (linked to a scan), list/filter, workflow
transitions (pending -> under_review -> confirmed/dismissed).

The transaction + transition rules currently live inline in api/reports.py and
should move here so the router stays thin.

STATUS: SCAFFOLD ONLY.
"""
from __future__ import annotations
