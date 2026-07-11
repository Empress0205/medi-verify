# MediGuard — Delivery Roadmap

**Guiding principle:** ship a working product on the *mock* engine first; defer
the heavy, risky real AI engine to late and keep it isolated behind the engine
seam so it can never cascade. Every phase is independently shippable.

Order follows the dependency chain (boot → contract → persistence → clients →
engine → dashboard → ops) and front-loads value while back-loading risk.

## Committed decisions
- **Engine deployment:** in-process now, seam kept for a later split.
- **Mobile history:** server-authoritative (scans persist in the API).
- **What we verify (Phase 5, #1):** TMDA *registration*, not physical authenticity.
  Outcomes are `registered / not_found / unknown / not_medicine` — the app never
  claims "counterfeit"; that stays a human reviewer conclusion in the dashboard.
- **Engine (#2):** provider-agnostic vision LLM. Primary **Google Gemini Flash**
  (free tier) reading the photo → structured fields in one step; Groq as fallback.
  Selected by `ENGINE` in `.env`. Replaced the legacy PaddleOCR+Ollama plan.
- **Register data (#3):** live sync from TMDA's public portal API into a local
  `medicines` table; the CSV in `data/` is the offline seed/fallback.

## Phases

| # | Phase | Goal | Done when |
|---|-------|------|-----------|
| 0 | Restructure | Monorepo layout | ✅ done |
| 1 | Make it boot | `services/api` runs on the **mock** engine | ✅ done — uvicorn starts, tables create, all endpoints respond |
| 2 | Lock the contract | One source for enums/schemas; confidence = 0.0–1.0 | ✅ done — enums single-sourced, confidence 0–1 enforced (422 on breach), `packages/contracts/openapi.json` frozen |
| 3 | Persistence + workflow | `/verify` writes a Scan; reports link scans; fix analytics trend; wire admin auth | ✅ done — 17/17 e2e checks pass (`services/api/tests/smoke_e2e.py`) |
| 4 | Connect mobile | Flutter → one API; fix confidence display; wire report screen; real history | ✅ live-verified on emulator — app boots, real `POST /reports` → `201`, row persisted (Arusha/AfyaPharmacy). Confidence display, field name (`file`→`image`), scan_id link, faked-history removal all shipped. Report success screen now shows backend's real code (needs rebuild to see live). |
| 5 | Real engine | Gemini vision → fields → TMDA `medicines` match → registered/not_found | ✅ done — live-verified: real Doxyzen label → `registered 0.97` (exact reg match) surfacing registration status + physical description; invented pack → `not_found`; non-medicine → `not_medicine`. TMDA sync loads 5,374 products; `ENGINE=gemini` switch works over HTTP. Eval harness in `tests/eval_register.py` (needs real photos to calibrate). |
| 6 | Dashboard frontend | Build the missing Vite/React `src`; consume `/analytics` + `/reports`; admin login | ✅ done — green-brand SaaS app (sidebar shell). Views: Overview (KPIs, status donut, trend lines), Reports (filter/sort/paginate + detail drawer + CSV export), Scans (surfaces verification events via new `/scans` endpoints), Regions (bubble map + hotspots). Verified live via headless Chrome. |
| 6b | Backend: scans API | Expose the persisted scans for the dashboard | ✅ done — `GET /scans` (list, admin) + `GET /scans/stats` (detection aggregates + trend). |
| 7 | Harden & ops | docker-compose (api+ollama+db), Alembic, tests, CI, rate limiting, CORS, secrets, drop ngrok | reproducible deploy, green CI |

## Fixes folded into the relevant phase
- P2: confidence 0.0–1.0 canonical; `enums.py` single source; `medicine_info` shape.
- P3: persist Scan on `/verify`; analytics trend keyed by year-month; admin auth guard.
- P4: Flutter confidence display; report screen → `POST /reports`; drop faked sample history.
- P5: register now synced live from the TMDA API (`infra/tmda_sync.py`); the old
  CSV `skiprows` bug is moot but the CSV remains as offline seed.
- P7: remove `"*"` when `allow_credentials=True`; rate limiting; secrets management;
  schedule the TMDA sync (cron) + surface "register last synced" in the dashboard.

## Current position
Phases 0–6 done. The verification engine is now **real**: photo → Gemini vision →
TMDA register match → registered/not_found, live-verified end to end. Set
`ENGINE=gemini` in `services/api/.env` (key already in place) to run it; leave
`ENGINE=mock` for keyless dev. **Remaining: Phase 7** (ops/hardening) + calibrate
against real photos via `tests/eval_register.py`. Legacy note below predates P5.

<!-- superseded by the above; kept for history -->
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
