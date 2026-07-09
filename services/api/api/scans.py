"""
Scan endpoints (admin-guarded) — surface the verification events that /verify
persists to the `scans` table.

  GET /scans        -> filtered list of scans
  GET /scans/stats  -> detection aggregates for the dashboard
"""
from datetime import datetime, date
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from infra.db import get_db
from infra.orm import Scan, ScanStatus
from api.auth import require_admin
from domain.schemas import ScanResponse, ScanStats, ScanTrendPoint

router = APIRouter(prefix="/scans", tags=["Scans"])


@router.get("/stats", response_model=ScanStats)
async def scan_stats(
    db: AsyncSession = Depends(get_db),
    _admin: str = Depends(require_admin),
):
    scans = (await db.execute(select(Scan))).scalars().all()
    total = len(scans)

    def count(s):
        return sum(1 for x in scans if x.status == s)

    verified = count(ScanStatus.verified)
    counterfeit = count(ScanStatus.counterfeit)
    unknown = count(ScanStatus.unknown)
    not_medicine = count(ScanStatus.not_medicine)

    medicine_scans = verified + counterfeit  # scans that resolved to a real medicine
    counterfeit_rate = round((counterfeit / medicine_scans * 100) if medicine_scans else 0, 1)
    avg_confidence = round(sum(s.confidence_score for s in scans) / total if total else 0, 3)

    # 6-month trend keyed by calendar year-month
    now = datetime.utcnow()
    order, labels, buckets = [], {}, {}
    ym = now.year * 12 + (now.month - 1)
    for i in range(5, -1, -1):
        yy, mm = divmod(ym - i, 12)
        key = f"{yy:04d}-{mm + 1:02d}"
        order.append(key)
        labels[key] = date(yy, mm + 1, 1).strftime("%b")
        buckets[key] = {"scans": 0, "counterfeit": 0}
    for s in scans:
        key = s.scanned_at.strftime("%Y-%m")
        if key in buckets:
            buckets[key]["scans"] += 1
            if s.status == ScanStatus.counterfeit:
                buckets[key]["counterfeit"] += 1

    trend = [
        ScanTrendPoint(month=labels[k], scans=buckets[k]["scans"], counterfeit=buckets[k]["counterfeit"])
        for k in order
    ]

    return ScanStats(
        total=total, verified=verified, counterfeit=counterfeit, unknown=unknown,
        not_medicine=not_medicine, counterfeit_rate=counterfeit_rate,
        avg_confidence=avg_confidence, trend=trend,
    )


@router.get("", response_model=list[ScanResponse])
async def list_scans(
    status: str | None = Query(None),
    search: str | None = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=500),
    db: AsyncSession = Depends(get_db),
    _admin: str = Depends(require_admin),
):
    q = select(Scan).order_by(Scan.scanned_at.desc())
    if status and status in {s.value for s in ScanStatus}:
        q = q.where(Scan.status == status)
    if search:
        term = f"%{search}%"
        q = q.where(Scan.medicine_name.ilike(term) | Scan.manufacturer.ilike(term))
    q = q.offset(skip).limit(limit)
    rows = (await db.execute(q)).scalars().all()
    return list(rows)
