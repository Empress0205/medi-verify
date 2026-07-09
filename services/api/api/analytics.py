"""
GET /analytics
Returns everything the React dashboard needs in one call:
  - stat counts
  - 6-month trend
  - reports per region
  - reports per category
  - top pharmacies
  - top medicines
  - confirmation rate
  - avg AI confidence
"""

from datetime import datetime, date
from collections import defaultdict
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from infra.db import get_db
from infra.orm import Report, ReportStatus
from api.auth import require_admin
from domain.schemas import (
    AnalyticsResponse,
    DashboardStats,
    TrendPoint,
    RegionPoint,
    CategoryPoint,
    PharmacyPoint,
    MedicinePoint,
)

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("", response_model=AnalyticsResponse)
async def get_analytics(
    db: AsyncSession = Depends(get_db),
    _admin: str = Depends(require_admin),
):
    all_reports_result = await db.execute(select(Report))
    reports = all_reports_result.scalars().all()

    # ── Counts ────────────────────────────────────────────────────────────────
    total        = len(reports)
    pending      = sum(1 for r in reports if r.status == ReportStatus.pending)
    under_review = sum(1 for r in reports if r.status == ReportStatus.under_review)
    confirmed    = sum(1 for r in reports if r.status == ReportStatus.confirmed)
    dismissed    = sum(1 for r in reports if r.status == ReportStatus.dismissed)

    # ── 6-month trend (keyed by calendar year-month, not month name) ──────────
    now = datetime.utcnow()
    order: list[str] = []            # year-month keys, oldest → newest
    labels: dict[str, str] = {}      # key → display label (e.g. "Jul")
    buckets: dict[str, dict] = {}
    ym = now.year * 12 + (now.month - 1)
    for i in range(5, -1, -1):
        yy, mm = divmod(ym - i, 12)
        key = f"{yy:04d}-{mm + 1:02d}"
        order.append(key)
        labels[key] = date(yy, mm + 1, 1).strftime("%b")
        buckets[key] = {"reports": 0, "confirmed": 0}

    for r in reports:
        key = r.submitted_at.strftime("%Y-%m")
        if key in buckets:
            buckets[key]["reports"] += 1
            if r.status == ReportStatus.confirmed:
                buckets[key]["confirmed"] += 1

    trend = [
        TrendPoint(month=labels[k], reports=buckets[k]["reports"], confirmed=buckets[k]["confirmed"])
        for k in order
    ]

    # ── By region ─────────────────────────────────────────────────────────────
    region_counts: dict[str, int] = defaultdict(int)
    for r in reports:
        region_counts[r.region] += 1
    regions = sorted(
        [RegionPoint(region=k, reports=v) for k, v in region_counts.items()],
        key=lambda x: x.reports, reverse=True,
    )

    # ── By category ───────────────────────────────────────────────────────────
    cat_counts: dict[str, int] = defaultdict(int)
    for r in reports:
        cat_counts[r.category] += 1
    categories = sorted(
        [CategoryPoint(name=k, value=v) for k, v in cat_counts.items()],
        key=lambda x: x.value, reverse=True,
    )

    # ── Top pharmacies ────────────────────────────────────────────────────────
    pharm_counts: dict[str, int] = defaultdict(int)
    for r in reports:
        pharm_counts[r.pharmacy] += 1
    top_pharmacies = sorted(
        [PharmacyPoint(name=k, count=v) for k, v in pharm_counts.items()],
        key=lambda x: x.count, reverse=True,
    )[:10]

    # ── Top medicines ─────────────────────────────────────────────────────────
    med_counts: dict[str, int] = defaultdict(int)
    for r in reports:
        med_counts[r.medicine_name] += 1
    top_medicines = sorted(
        [MedicinePoint(name=k, count=v) for k, v in med_counts.items()],
        key=lambda x: x.count, reverse=True,
    )[:10]

    # ── Rates ─────────────────────────────────────────────────────────────────
    confirmation_rate = round((confirmed / total * 100) if total else 0, 1)
    avg_confidence    = round(
        sum(r.confidence for r in reports) / total if total else 0, 1
    )

    return AnalyticsResponse(
        stats=DashboardStats(
            total=total,
            pending=pending,
            under_review=under_review,
            confirmed=confirmed,
            dismissed=dismissed,
        ),
        trend=trend,
        regions=regions,
        categories=categories,
        top_pharmacies=top_pharmacies,
        top_medicines=top_medicines,
        confirmation_rate=confirmation_rate,
        avg_confidence=avg_confidence,
    )