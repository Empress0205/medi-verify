"""Sync the TMDA register into the local `medicines` table.

Source: the public JSON endpoint the TMDA portal itself uses for its
"registered medicines" search (imis2.tmda.go.tz). It's undocumented, so this is
a best-effort mirror — user scans always query our LOCAL copy, and the CSV in
data/ remains the offline fallback seed if the endpoint ever changes.

Run manually:   python -m infra.tmda_sync
"""
import asyncio
import warnings
from datetime import datetime

import httpx
from sqlalchemy import delete

from infra.db import AsyncSessionLocal, init_db
from infra.orm import Medicine, RegisterSync
from infra.normalize import normalize_cert

TMDA_URL = "https://imis2.tmda.go.tz/publicaccess/onSearchPublicRegisteredproducts"
SECTION_ID = 2            # human medicines
SUB_MODULES = "7,8,9"     # the three register sub-modules that hold products
PAGE_SIZE = 500


def _parse_date(value):
    if not value:
        return None
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
        try:
            return datetime.strptime(str(value)[:19], fmt)
        except ValueError:
            continue
    return None


def _clean(value):
    if value is None:
        return None
    s = str(value).strip()
    return s or None


async def fetch_all(client: httpx.AsyncClient) -> list[dict]:
    rows: list[dict] = []
    skip = 0
    while True:
        params = {
            "skip": skip, "take": PAGE_SIZE, "section_id": SECTION_ID,
            "sub_modulesin": SUB_MODULES, "extra_paramsdata": "{}",
        }
        r = await client.get(TMDA_URL, params=params, timeout=90)
        r.raise_for_status()
        payload = r.json()
        batch = payload.get("data") or []
        if not batch:
            break
        rows.extend(batch)
        total = payload.get("totalCount", 0)
        skip += PAGE_SIZE
        if skip >= total:
            break
    return rows


def _to_medicine(rec: dict) -> Medicine:
    cert = _clean(rec.get("certificate_no")) or ""
    return Medicine(
        id=int(rec["product_id"]),
        certificate_no=cert,
        cert_no_norm=normalize_cert(cert),
        brand_name=_clean(rec.get("brand_name")),
        generic_name=_clean(rec.get("generic_name")),
        active_ingredient=_clean(rec.get("active_ingredient")),
        atc_description=_clean(rec.get("atc_code_description")),
        manufacturer=_clean(rec.get("manufacturer")),
        manufacturer_country=_clean(rec.get("manufacturer_country")),
        registrant=_clean(rec.get("registrant")),
        dosage_form=_clean(rec.get("dosage_form")),
        strength=_clean(rec.get("product_strength")),
        physical_description=_clean(rec.get("physical_description")),
        registration_status=_clean(rec.get("registration_status")) or _clean(rec.get("validity_status")),
        cert_issue_date=_parse_date(rec.get("certificate_issue_date")),
        cert_expiry_date=_parse_date(rec.get("app_expiry_Date")),
        synced_at=datetime.utcnow(),
    )


async def sync_register(verbose: bool = True) -> dict:
    """Full replace of the medicines table from the TMDA API. Atomic."""
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")  # TMDA TLS chain is quirky
            async with httpx.AsyncClient(verify=False) as client:
                raw = await fetch_all(client)
    except Exception as e:
        async with AsyncSessionLocal() as db:
            db.add(RegisterSync(record_count=0, source="tmda_api", ok=False, note=str(e)[:400]))
            await db.commit()
        if verbose:
            print(f"[sync] TMDA sync FAILED: {e}")
        return {"ok": False, "error": str(e)}

    # dedupe by product_id
    by_id: dict[int, dict] = {}
    for rec in raw:
        try:
            by_id[int(rec["product_id"])] = rec
        except (KeyError, TypeError, ValueError):
            continue
    meds = [_to_medicine(r) for r in by_id.values()]

    async with AsyncSessionLocal() as db:
        await db.execute(delete(Medicine))
        db.add_all(meds)
        db.add(RegisterSync(record_count=len(meds), source="tmda_api", ok=True))
        await db.commit()

    if verbose:
        print(f"[sync] synced {len(meds)} medicines from the TMDA register")
    return {"ok": True, "count": len(meds)}


if __name__ == "__main__":
    async def _main():
        await init_db()
        await sync_register()
    asyncio.run(_main())
