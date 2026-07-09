# MediGuard — Delivery Roadmap

**Guiding principle:** ship a working product on the *mock* engine first; defer
the heavy, risky real AI engine to late and keep it isolated behind the engine
seam so it can never cascade. Every phase is independently shippable.

Order follows the dependency chain (boot → contract → persistence → clients →
engine → dashboard → ops) and front-loads value while back-loading risk.

## Committed decisions
- **Engine deployment:** in-process now, seam kept for a later split.
- **Mobile history:** server-authoritative (scans persist in the API).

## Phases

| # | Phase | Goal | Done when |
|---|-------|------|-----------|
| 0 | Restructure | Monorepo layout | ✅ done |
| 1 | Make it boot | `services/api` runs on the **mock** engine | ✅ done — uvicorn starts, tables create, all endpoints respond |
| 2 | Lock the contract | One source for enums/schemas; confidence = 0.0–1.0 | ✅ done — enums single-sourced, confidence 0–1 enforced (422 on breach), `packages/contracts/openapi.json` frozen |
| 3 | Persistence + workflow | `/verify` writes a Scan; reports link scans; fix analytics trend; wire admin auth | ✅ done — 17/17 e2e checks pass (`services/api/tests/smoke_e2e.py`) |
| 4 | Connect mobile | Flutter → one API; fix confidence display; wire report screen; real history | ✅ live-verified on emulator — app boots, real `POST /reports` → `201`, row persisted (Arusha/AfyaPharmacy). Confidence display, field name (`file`→`image`), scan_id link, faked-history removal all shipped. Report success screen now shows backend's real code (needs rebuild to see live). |
| 5 | Real engine | Port `legacy/backend1` pipeline into `inprocess.py`; `skiprows=2`; CSV → `medicines` table; merge OCR/LLM deps; flip config | a real photo yields a real result |
| 6 | Dashboard frontend | Build the missing Vite/React `src`; consume `/analytics` + `/reports`; admin login | ✅ done — green-brand SaaS app (sidebar shell). Views: Overview (KPIs, status donut, trend lines), Reports (filter/sort/paginate + detail drawer + CSV export), Scans (surfaces verification events via new `/scans` endpoints), Regions (bubble map + hotspots). Verified live via headless Chrome. |
| 6b | Backend: scans API | Expose the persisted scans for the dashboard | ✅ done — `GET /scans` (list, admin) + `GET /scans/stats` (detection aggregates + trend). |
| 7 | Harden & ops | docker-compose (api+ollama+db), Alembic, tests, CI, rate limiting, CORS, secrets, drop ngrok | reproducible deploy, green CI |

## Fixes folded into the relevant phase
- P2: confidence 0.0–1.0 canonical; `enums.py` single source; `medicine_info` shape.
- P3: persist Scan on `/verify`; analytics trend keyed by year-month; admin auth guard.
- P4: Flutter confidence display; report screen → `POST /reports`; drop faked sample history.
- P5: `tmda_loader.py` `skiprows=2` (currently `skiprows=8` drops 6 medicines).
- P7: remove `"*"` when `allow_credentials=True`; rate limiting; secrets management.

## Current position
Phases 0–4 and **6 done**. The full stack runs live: Flutter app (emulator) →
FastAPI backend → SQLite → React admin dashboard, all on the mock verification
engine. Verified live: mobile report submit → `POST /reports 201` → persisted →
appears in the dashboard with working triage workflow. **Next: Phase 5** (real
OCR/LLM engine) or Phase 7 (harden & ops).

Dashboard: `apps/dashboard` (Vite/React) — green-brand SaaS console with
Overview / Reports / Scans / Regions. `npm install && npm run dev`, then log in
with `admin` / `admin123`. Reads `VITE_API_BASE_URL` (defaults
`http://localhost:8000`).

Emulator notes: build needs Windows Developer Mode (symlinks). `image_picker
0.8.7` won't open camera/gallery on this Android 16 emulator, so the scan path
couldn't be driven headlessly — verified via the report path instead. Consider
upgrading `image_picker` in Phase 5/6.

Auth note: default admin seeded on startup = `admin` / `admin123` (config
`ADMIN_*`; change in prod). Password hashing uses `bcrypt` directly (passlib was
dropped — incompatible with bcrypt 5.x).
