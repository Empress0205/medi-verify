from __future__ import annotations
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from domain.enums import (
    ExpiryStatus,
    RegistrationValidity,
    ReportStatus,
    ScanStatus,
    Severity,
)


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

    # ── TMDA register match evidence (populated when a record is matched) ──
    reg_no:               Optional[str] = None
    registration_status:  Optional[str] = None   # e.g. "Registered/Compliant"
    registration_expiry:  Optional[str] = None   # when the registration itself lapses
    physical_description: Optional[str] = None   # what the genuine product looks like


class ExtractedFields(BaseModel):
    """Raw fields read off the packaging by the vision engine (pre-matching).

    When several photos of the same pack are supplied (front, back, blister),
    the engine reads them together and returns ONE combined field set.
    """
    is_medicine:   bool = True     # engine's judgment: is this medicine packaging at all?
    medicine_name: Optional[str] = None
    strength:      Optional[str] = None
    reg_no:        Optional[str] = None
    batch_number:  Optional[str] = None
    mfg_date:      Optional[str] = None
    expiry_date:   Optional[str] = None
    manufacturer:  Optional[str] = None

    # Guardrail: the photos appear to show DIFFERENT products, so their fields
    # must not be stitched together into a false match.
    conflict:      bool = False


class CaptureHint(BaseModel):
    """Tells the app whether another photo of the pack would improve the result.

    The decisive field (the registration number) and the safety-critical field
    (the expiry) are often printed on a different panel from the brand name —
    so one photo of the front frequently isn't enough. A clean register match is
    NOT sufficient grounds to stop asking: we may still be blind to the expiry.
    """
    needs_more: bool = False
    missing:    list[str] = Field(default_factory=list)   # e.g. ["registration number"]
    prompt:     Optional[str] = None                      # user-facing guidance


class SafetyInfo(BaseModel):
    """The safety layer that sits on top of the registration verdict.

    Registration answers "is this product approved?" — it says nothing about
    whether the box in your hand is still in date. Both matter, so they are
    reported separately and `severity` decides how the result is presented.
    """
    # The pack in the user's hand (from the printed label)
    expiry_status:   ExpiryStatus
    expiry_date:     Optional[str] = None    # ISO; month-only dates resolve to end-of-month
    days_to_expiry:  Optional[int] = None

    # The product's TMDA registration certificate (from the register)
    registration_validity: RegistrationValidity
    registration_expiry:   Optional[str] = None

    # How to present it. `danger` is only ever used for facts we actually read.
    severity:   Severity
    headline:   str
    detail:     Optional[str] = None
    reportable: bool = False


class VerifyResponse(BaseModel):
    success:          bool
    status:           ScanStatus                       # canonical enum, no free-form strings
    confidence_score: float = Field(ge=0.0, le=1.0)    # CANONICAL: 0.0–1.0, format to % at UI
    medicine_info:    Optional[MedicineInfo] = None
    safety:           Optional[SafetyInfo] = None      # expiry / registration-validity layer
    capture:          Optional[CaptureHint] = None     # would another photo help?
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
    month:     str
    scans:     int
    not_found: int


class ScanStats(BaseModel):
    total:          int
    registered:     int
    not_found:      int
    unknown:        int
    not_medicine:   int
    not_found_rate: float             # % of readable medicine scans not on the register
    avg_confidence: float             # 0.0–1.0
    trend:          list[ScanTrendPoint]