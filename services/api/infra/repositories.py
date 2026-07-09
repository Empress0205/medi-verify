"""
Repositories — the only place that touches the ORM/session for each aggregate.
Keeps routers and services free of raw SQLAlchemy queries.

    ScanRepository    : create/get scans, list by device
    ReportRepository  : create/get/list/update/delete reports
    MedicineRepository: query the TMDA `medicines` table for the matcher
    AdminRepository   : lookup admin users for auth

STATUS: SCAFFOLD ONLY. Extract the queries currently inline in
api/reports.py and api/analytics.py into these classes.
"""
from __future__ import annotations
