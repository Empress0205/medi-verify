import random
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database import get_db
from orm import Report, ReportStatus
from schema import (
    ReportCreateRequest,
    ReportResponse,
    StatusUpdateRequest,
)

router = APIRouter(prefix="/reports", tags=["Reports"])

VALID_STATUSES = {s.value for s in ReportStatus}

def _generate_report_code() -> str:
    return f"RPT-{random.randint(10000, 99999)}"

def _orm_to_schema(r: Report) -> ReportResponse:
    return ReportResponse(
        id=r.id,
        report_code=r.report_code,
        medicine_name=r.medicine_name,
        manufacturer=r.manufacturer,
        batch_number=r.batch_number,
        expiry_date=r.expiry_date,
        confidence=r.confidence,
        region=r.region,
        street=r.street,
        pharmacy=r.pharmacy,
        category=r.category,
        description=r.description,
        status=r.status,
        submitted_at=r.submitted_at,
        reviewed_at=r.reviewed_at,
        admin_notes=r.admin_notes,
    )

# ── Flutter: submit report ─────────────────────────────────────────────────────
@router.post("", response_model=dict, status_code=201)
async def submit_report(
    body: ReportCreateRequest,
    db: AsyncSession = Depends(get_db),
):
    report = Report(
        report_code=_generate_report_code(),
        scan_id=body.scan_id,
        medicine_name=body.medicine_name,
        manufacturer=body.manufacturer,
        batch_number=body.batch_number,
        expiry_date=body.expiry_date,
        confidence=body.confidence,
        region=body.region,
        street=body.street,
        pharmacy=body.pharmacy,
        category=body.category,
        description=body.description,
        status=ReportStatus.pending,
        submitted_at=datetime.utcnow(),
    )
    db.add(report)
    await db.flush()
    await db.refresh(report)
    return {
        "success": True,
        "report_id": report.id,
        "report_code": report.report_code,
        "message": "Report submitted successfully.",
    }

# ── List reports ───────────────────────────────────────────────────────────────
@router.get("", response_model=list[ReportResponse])
async def list_reports(
    status:   str | None = Query(None),
    region:   str | None = Query(None),
    category: str | None = Query(None),
    search:   str | None = Query(None),
    skip:     int = Query(0, ge=0),
    limit:    int = Query(100, le=500),
    db: AsyncSession = Depends(get_db),
):
    q = select(Report).order_by(Report.submitted_at.desc())
    if status and status in VALID_STATUSES:
        q = q.where(Report.status == status)
    if region:
        q = q.where(Report.region.ilike(f"%{region}%"))
    if category:
        q = q.where(Report.category == category)
    if search:
        term = f"%{search}%"
        q = q.where(
            Report.medicine_name.ilike(term)
            | Report.report_code.ilike(term)
            | Report.pharmacy.ilike(term)
        )
    q = q.offset(skip).limit(limit)
    result = await db.execute(q)
    return [_orm_to_schema(r) for r in result.scalars().all()]

# ── Single report ──────────────────────────────────────────────────────────────
@router.get("/{report_id}", response_model=ReportResponse)
async def get_report(
    report_id: str,
    db: AsyncSession = Depends(get_db),
):
    r = await db.get(Report, report_id)
    if not r:
        raise HTTPException(status_code=404, detail="Report not found")
    return _orm_to_schema(r)

# ── Update status ──────────────────────────────────────────────────────────────
ALLOWED_TRANSITIONS = {
    ReportStatus.pending:      {ReportStatus.under_review, ReportStatus.dismissed},
    ReportStatus.under_review: {ReportStatus.confirmed, ReportStatus.dismissed},
    ReportStatus.confirmed:    set(),
    ReportStatus.dismissed:    set(),
}

@router.patch("/{report_id}/status", response_model=ReportResponse)
async def update_status(
    report_id: str,
    body: StatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
):
    r = await db.get(Report, report_id)
    if not r:
        raise HTTPException(status_code=404, detail="Report not found")
    if body.status not in VALID_STATUSES:
        raise HTTPException(status_code=400, detail=f"Invalid status: {body.status}")
    new_status = ReportStatus(body.status)
    current    = ReportStatus(r.status)
    if new_status not in ALLOWED_TRANSITIONS[current]:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot transition from '{current.value}' to '{new_status.value}'",
        )
    r.status      = new_status
    r.reviewed_at = datetime.utcnow()
    if body.admin_notes:
        r.admin_notes = body.admin_notes
    await db.flush()
    await db.refresh(r)
    return _orm_to_schema(r)

# ── Delete ─────────────────────────────────────────────────────────────────────
@router.delete("/{report_id}", status_code=204)
async def delete_report(
    report_id: str,
    db: AsyncSession = Depends(get_db),
):
    r = await db.get(Report, report_id)
    if not r:
        raise HTTPException(status_code=404, detail="Report not found")
    await db.delete(r)