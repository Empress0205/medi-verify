from __future__ import annotations
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from domain.enums import ScanStatus, ReportStatus


# ── Verify endpoint (Flutter → backend) ───────────────────────────────────────

class MedicineInfo(BaseModel):
    name:              str
    manufacturer:      str
    batch_number:      str
    manufacture_date:  Optional[str] = None
    expiry_date:       str
    scan_time:         str
    description:       Optional[str] = None
    active_ingredient: Optional[str] = None
    dosage:            Optional[str] = None
    warnings:          Optional[list[str]] = None


class VerifyResponse(BaseModel):
    success:          bool
    status:           ScanStatus                       # canonical enum, no free-form strings
    confidence_score: float = Field(ge=0.0, le=1.0)    # CANONICAL: 0.0–1.0, format to % at UI
    medicine_info:    Optional[MedicineInfo] = None
    message:          Optional[str] = None
    error_message:    Optional[str] = None
    scan_id:          Optional[str] = None             # id of the persisted Scan row


# ── Report submission (Flutter report screen → backend) ───────────────────────

class ReportCreateRequest(BaseModel):
    scan_id:      Optional[str] = None   # UUID of the scan that triggered this report

    # Medicine info snapshot
    medicine_name: str
    manufacturer:  str
    batch_number:  str
    expiry_date:   str
    confidence:    float = Field(0.0, ge=0.0, le=1.0)   # canonical 0.0–1.0

    # Pharmacy location
    region:   str = Field(..., min_length=1)
    street:   str = ""
    pharmacy: str = Field(..., min_length=1)

    # Report content
    category:    str
    description: Optional[str] = None


class ReportResponse(BaseModel):
    id:           str
    report_code:  str
    scan_id:      Optional[str] = None
    medicine_name: str
    manufacturer:  str
    batch_number:  str
    expiry_date:   str
    confidence:    float
    region:        str
    street:        str
    pharmacy:      str
    category:      str
    description:   Optional[str]
    status:        ReportStatus
    submitted_at:  datetime
    reviewed_at:   Optional[datetime]
    admin_notes:   Optional[str]

    class Config:
        from_attributes = True


# ── Admin status update ────────────────────────────────────────────────────────

class StatusUpdateRequest(BaseModel):
    status:      str          # pending | under_review | confirmed | dismissed
    admin_notes: Optional[str] = None


# ── Analytics schemas ──────────────────────────────────────────────────────────

class DashboardStats(BaseModel):
    total:       int
    pending:     int
    under_review: int
    confirmed:   int
    dismissed:   int


class TrendPoint(BaseModel):
    month:     str
    reports:   int
    confirmed: int


class RegionPoint(BaseModel):
    region:  str
    reports: int


class CategoryPoint(BaseModel):
    name:  str
    value: int


class PharmacyPoint(BaseModel):
    name:  str
    count: int


class MedicinePoint(BaseModel):
    name:  str
    count: int


class AnalyticsResponse(BaseModel):
    stats:            DashboardStats
    trend:            list[TrendPoint]
    regions:          list[RegionPoint]
    categories:       list[CategoryPoint]
    top_pharmacies:   list[PharmacyPoint]
    top_medicines:    list[MedicinePoint]
    confirmation_rate: float
    avg_confidence:   float


# ── Auth ───────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"


# ── Scans (verification events) ────────────────────────────────────────────────

class ScanResponse(BaseModel):
    id:               str
    medicine_name:    str
    manufacturer:     str
    batch_number:     str
    expiry_date:      str
    status:           ScanStatus
    confidence_score: float
    notes:            Optional[str]
    scanned_at:       datetime

    class Config:
        from_attributes = True


class ScanTrendPoint(BaseModel):
    month:       str
    scans:       int
    counterfeit: int


class ScanStats(BaseModel):
    total:            int
    verified:         int
    counterfeit:      int
    unknown:          int
    not_medicine:     int
    counterfeit_rate: float           # % of real-medicine scans flagged counterfeit
    avg_confidence:   float           # 0.0–1.0
    trend:            list[ScanTrendPoint]