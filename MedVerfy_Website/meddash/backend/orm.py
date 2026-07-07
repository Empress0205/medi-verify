import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, Text, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from database import Base


class ReportStatus(str, enum.Enum):
    pending      = "pending"
    under_review = "under_review"
    confirmed    = "confirmed"
    dismissed    = "dismissed"


class ScanStatus(str, enum.Enum):
    verified   = "verified"
    counterfeit = "counterfeit"
    unknown    = "unknown"
    not_medicine = "not_medicine"


def _new_uuid() -> str:
    return str(uuid.uuid4())


# ── Scan (medicine verification result from Flutter) ──────────────────────────
class Scan(Base):
    __tablename__ = "scans"

    id:               Mapped[str]   = mapped_column(String, primary_key=True, default=_new_uuid)
    medicine_name:    Mapped[str]   = mapped_column(String(255))
    manufacturer:     Mapped[str]   = mapped_column(String(255))
    batch_number:     Mapped[str]   = mapped_column(String(100))
    expiry_date:      Mapped[str]   = mapped_column(String(50))
    status:           Mapped[str]   = mapped_column(SAEnum(ScanStatus), default=ScanStatus.unknown)
    confidence_score: Mapped[float] = mapped_column(Float, default=0.0)
    notes:            Mapped[str | None] = mapped_column(Text, nullable=True)
    scanned_at:       Mapped[datetime]  = mapped_column(DateTime, default=datetime.utcnow)

    # Relationship to report (optional — not every scan becomes a report)
    report: Mapped["Report | None"] = relationship("Report", back_populates="scan", uselist=False)


# ── Report (submitted by user from Flutter report screen) ─────────────────────
class Report(Base):
    __tablename__ = "reports"

    id:           Mapped[str] = mapped_column(String, primary_key=True, default=_new_uuid)
    report_code:  Mapped[str] = mapped_column(String(30), unique=True)  # e.g. RPT-84231

    # Linked scan (carries medicine info)
    scan_id: Mapped[str | None] = mapped_column(ForeignKey("scans.id"), nullable=True)
    scan:    Mapped["Scan | None"] = relationship("Scan", back_populates="report")

    # Medicine info snapshot (denormalised so report stands alone even if scan deleted)
    medicine_name: Mapped[str] = mapped_column(String(255))
    manufacturer:  Mapped[str] = mapped_column(String(255))
    batch_number:  Mapped[str] = mapped_column(String(100))
    expiry_date:   Mapped[str] = mapped_column(String(50))
    confidence:    Mapped[float] = mapped_column(Float, default=0.0)

    # Pharmacy location
    region:   Mapped[str] = mapped_column(String(100))
    street:   Mapped[str] = mapped_column(String(200))
    pharmacy: Mapped[str] = mapped_column(String(200))

    # Report content
    category:    Mapped[str]        = mapped_column(String(100))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Workflow
    status:       Mapped[str]      = mapped_column(SAEnum(ReportStatus), default=ReportStatus.pending)
    submitted_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    reviewed_at:  Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    admin_notes:  Mapped[str | None]      = mapped_column(Text, nullable=True)


# ── Admin user ─────────────────────────────────────────────────────────────────
class AdminUser(Base):
    __tablename__ = "admin_users"

    id:              Mapped[str] = mapped_column(String, primary_key=True, default=_new_uuid)
    username:        Mapped[str] = mapped_column(String(100), unique=True, index=True)
    email:           Mapped[str] = mapped_column(String(255), unique=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    created_at:      Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)