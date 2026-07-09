# MediGuard — Architecture

Consolidates the previous **three uncoordinated backends** into one API, a
pluggable verification engine, one shared contract, and two clients.

## Monorepo layout

```
mediguard/
  apps/
    mobile/            # Flutter consumer app        (was medicine_verification_app)
    dashboard/         # React admin dashboard        (was .../mediguard-dashboard)
  services/
    api/               # single FastAPI backend       (base: meddash/backend)
      main.py            app factory, lifespan, CORS
      config.py          pydantic-settings (env-driven)
      api/               routers = HTTP only, no logic
        verify.py          POST /verify           (public / app-token)
        reports.py         /reports CRUD          (POST public, rest admin)
        analytics.py       GET  /analytics        (admin)
        auth.py            POST /auth/login       (admin)          [scaffold]
        scans.py           GET  /scans/{id}       (public)         [scaffold]
      services/          use-cases (orchestration, transactions)   [scaffold]
        verification_service.py  report_service.py  analytics_service.py
      domain/
        schemas.py         pydantic DTOs (the wire contract)
        enums.py           ScanStatus / ReportStatus (single source) [new]
      infra/
        db.py  orm.py      async SQLAlchemy + SQLite
        repositories.py    query layer                              [scaffold]
        engine/            the pluggable verification engine
          base.py            VerificationEngine port                [new]
          inprocess.py       real OCR+LLM+match, in-process         [scaffold]
          remote.py          HTTP -> inference service              [scaffold]
          mock.py            deterministic fake (was verification.py)
          ocr.py  llm.py  matcher.py  tmda_loader.py  (ported from backend1)
      data/              (per-service data if needed)
    inference/           optional split-out engine (Phase 2)        [placeholder]
  packages/
    contracts/           shared status/confidence/field contract    [doc]
  data/
    tmda_medicines.csv   TMDA registry (was medicine_database.CSV)
  docs/
  legacy/                superseded code, kept for reference (see below)
```

## What moved (source -> destination)

| From | To |
|------|----|
| `medicine_verification_app/` | `apps/mobile/` |
| `MedVerfy_Website/meddash/mediguard-dashboard/` | `apps/dashboard/` |
| `MedVerfy_Website/meddash/backend/main.py` | `services/api/main.py` |
| `.../backend/config.py` | `services/api/config.py` |
| `.../backend/schema.py` | `services/api/domain/schemas.py` |
| `.../backend/orm.py` | `services/api/infra/orm.py` |
| `.../backend/database.py` | `services/api/infra/db.py` |
| `.../backend/verfiy.py` | `services/api/api/verify.py` |
| `.../backend/reports.py` | `services/api/api/reports.py` |
| `.../backend/analytics.py` | `services/api/api/analytics.py` |
| `.../backend/verification.py` | `services/api/infra/engine/mock.py` |
| `medverfy_backend/backend1/ocr_processor.py` | `services/api/infra/engine/ocr.py` |
| `.../backend1/llm_extractor.py` | `services/api/infra/engine/llm.py` |
| `.../backend1/matcher.py` | `services/api/infra/engine/matcher.py` |
| `.../backend1/database.py` (CSV loader) | `services/api/infra/engine/tmda_loader.py` |
| `.../backend1/medicine_database.CSV` | `data/tmda_medicines.csv` |

## Quarantined in `legacy/` (nothing deleted)

- `legacy/backend1/` — old flat verify app: `main.py`, `run.py`, `utils.py`,
  `config.py` (dead regex approach), `test.py` (stray Groq check), `requirements.txt`.
  **`main.py` still holds the real OCR->LLM->match orchestration** to port into
  `infra/engine/inprocess.py`.
- `legacy/misc/orphan_reports.py` — the old in-memory reports app (superseded by
  `api/reports.py`).
- `legacy/misc/vscode_settings/` — committed `.vscode`.
- `legacy/temp_images/` — committed OCR scratch images (`temp_*`).

## Status: structure only

Files were **relocated, not rewritten**. Python imports inside `services/api`
are still the old flat style and will NOT run until re-wired. That wiring is
deferred to the implementation phase because it depends on two open decisions:

- **Decision 1 — engine deployment**: in-process (default), split inference
  service, or mock-default. Selects the default in `infra/engine/` + config.
- **Decision 2 — mobile history**: server-authoritative (persist scans, needs
  `api/scans.py`) vs local-first (drop `api/scans.py`).

## Known fixes to fold in during wiring

- `tmda_loader.py`: CSV has a leading blank line + header -> use `skiprows=2`
  (current `skiprows=8` silently drops 6 real medicines).
- Confidence: standardize to `0.0–1.0`; format at UI (`mock.py` currently emits
  0–100; `backend1` emits 0–1; Flutter renders `x%` assuming 0–100).
- CORS: drop `"*"` when `allow_credentials=True` (invalid combo).
- Analytics 6-month trend: key buckets by year-month, not month abbreviation.
- Persist a `Scan` row on `/verify` (the `scans` table is currently never written).
- Wire admin auth (`api/auth.py`) to guard reports mutation + analytics.
- `apps/dashboard/`: only `index.html` shipped — `package.json` + `src/` missing.
