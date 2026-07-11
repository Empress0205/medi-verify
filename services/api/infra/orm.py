import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, Text, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from infra.db import Base
# Single source of truth for status values (re-exported for existing importers).
from domain.enums import ReportStatus, ScanStatus  # noqa: F401


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


# ── Medicine (a product on the TMDA register — synced from the public API) ─────
class Medicine(Base):
    __tablename__ = "medicines"

    # TMDA's own product id — stable, used as the PK for idempotent upserts
    id:               Mapped[int] = mapped_column(primary_key=True, autoincrement=False)

    certificate_no:   Mapped[str] = mapped_column(String(120), index=True)
    # normalized (uppercase, alphanumeric only) for robust matching against OCR
    cert_no_norm:     Mapped[str] = mapped_column(String(120), index=True)

    # Free-text register fields use Text (unbounded). TMDA values are unpredictable
    # in length — e.g. combination-vaccine generic names / active ingredients run to
    # hundreds of chars — and Postgres (unlike SQLite) enforces VARCHAR(n) limits,
    # so a bounded column silently overflowed and aborted the whole seed batch.
    brand_name:       Mapped[str | None] = mapped_column(Text, index=True)
    generic_name:     Mapped[str | None] = mapped_column(Text)
    active_ingredient: Mapped[str | None] = mapped_column(Text, nullable=True)
    atc_description:  Mapped[str | None] = mapped_column(Text, nullable=True)

    manufacturer:         Mapped[str | None] = mapped_column(Text)
    manufacturer_country: Mapped[str | None] = mapped_column(Text, nullable=True)
    registrant:           Mapped[str | None] = mapped_column(Text, nullable=True)

    dosage_form:      Mapped[str | None] = mapped_column(Text, nullable=True)
    strength:         Mapped[str | None] = mapped_column(Text, nullable=True)
    physical_description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # The registration's own validity — a match to a lapsed registration is not "green"
    registration_status: Mapped[str | None] = mapped_column(Text, nullable=True)
    cert_issue_date:  Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    cert_expiry_date: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    synced_at:        Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


# ── Register sync bookkeeping (for the "last synced" dashboard indicator) ──────
class RegisterSync(Base):
    __tablename__ = "register_sync"

    id:           Mapped[str] = mapped_column(String, primary_key=True, default=_new_uuid)
    synced_at:    Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    record_count: Mapped[int] = mapped_column(default=0)
    source:       Mapped[str] = mapped_column(String(40), default="tmda_api")  # tmda_api | csv
    ok:           Mapped[bool] = mapped_column(default=True)
    note:         Mapped[str | None] = mapped_column(Text, nullable=True)


# ── Admin user ─────────────────────────────────────────────────────────────────
class AdminUser(Base):
    __tablename__ = "admin_users"

    id:              Mapped[str] = mapped_column(String, primary_key=True, default=_new_uuid)
    username:        Mapped[str] = mapped_column(String(100), unique=True, index=True)
    email:           Mapped[str] = mapped_column(String(255), unique=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    created_at:      Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)