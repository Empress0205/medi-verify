# MediGuard API

FastAPI backend that powers both the Flutter mobile app and the React admin dashboard. It reads medicine packaging photos with a vision model, matches them against the TMDA register, stores scans and reports, and serves dashboard analytics.

## Project structure

```
services/api/
├── main.py              FastAPI app, CORS, lifespan (DB setup, TMDA sync), health routes
├── config.py            Settings, read from environment variables / .env
├── api/                 HTTP routers (no business logic)
│   ├── auth.py            POST /auth/login, admin seeding
│   ├── verify.py          POST /verify
│   ├── reports.py         /reports
│   ├── scans.py           /scans
│   └── analytics.py       /analytics
├── services/            Use cases (verification orchestration)
├── domain/
│   ├── enums.py           ScanStatus, ReportStatus, ExpiryStatus (single source of truth)
│   └── schemas.py         Pydantic request/response models (the wire contract)
├── infra/
│   ├── db.py, orm.py      Async SQLAlchemy engine and tables
│   ├── tmda_sync.py       Syncs the TMDA register from the public portal
│   ├── expiry.py          Expiry-date parsing
│   ├── normalize.py       Text normalisation for matching
│   └── engine/            Pluggable verification engine
│       ├── base.py          Engine interface
│       ├── gemini.py        Google Gemini vision
│       ├── mock.py          Deterministic fake (no API key needed)
│       ├── matcher.py       Match extracted fields to register records
│       └── safety.py        Expiry / registration-validity layer
├── tests/               End-to-end smoke test and register evaluation harness
├── Dockerfile
└── requirements.txt
```

## Quick start

```bash
cd services/api
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload
```

- API: <http://localhost:8000>
- Interactive docs: <http://localhost:8000/docs>
- Health: `GET /health`, register sync status: `GET /register/status`

With the default `ENGINE=mock`, everything runs without an API key. Set `ENGINE=gemini` and `GEMINI_API_KEY` to read real packaging.

## Configuration

All settings live in [`config.py`](config.py) and can be overridden with environment variables or a `.env` file (see [`.env.example`](.env.example)).

| Variable | Purpose | Default |
| --- | --- | --- |
| `DATABASE_URL` | SQLAlchemy URL (SQLite locally, Postgres in production) | `sqlite+aiosqlite:///./mediguard.db` |
| `SECRET_KEY` | JWT signing secret | placeholder — **must be set in production** |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | Dashboard admin account, re-synced on every start | `admin` / placeholder — **must be set in production** |
| `CORS_ORIGINS` | Allowed origins (JSON list) | local dev servers |
| `ENGINE` | `mock` or `gemini` | `mock` |
| `GEMINI_API_KEY`, `GEMINI_MODEL` | Gemini credentials and model | — |
| `REGISTER_SYNC_HOURS` | How often to refresh the TMDA register (0 disables) | `24` |

## Authentication

Admin endpoints need a JWT. The admin account is created from `ADMIN_USERNAME` / `ADMIN_PASSWORD` on startup.

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "<ADMIN_PASSWORD>"}'
```

Send the returned `access_token` as `Authorization: Bearer <token>`.

## API reference

### Public endpoints (used by the mobile app)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/verify` | Upload 1–3 photos of a pack (`image` or repeated `images` fields, `multipart/form-data`) and get a registration verdict |
| POST | `/reports` | Submit a suspicious-medicine report |

`/verify` returns:

```json
{
  "success": true,
  "status": "registered",
  "confidence_score": 0.97,
  "medicine_info": { "...": "fields read from the pack and the matched TMDA record" },
  "safety": { "...": "expiry and registration-validity flags" },
  "capture": { "...": "hint when another photo would help" },
  "message": "...",
  "scan_id": "uuid"
}
```

- `status` is one of `registered`, `not_found`, `unknown`, `not_medicine`. The API never returns "counterfeit"; that is a human decision made by confirming a report.
- `confidence_score` is always 0.0–1.0. Convert it to a percentage only in the UI.

### Admin endpoints (JWT required)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/reports` | List reports (filters: `status`, `region`, `category`, `search`, `skip`, `limit`) |
| GET | `/reports/{id}` | Report detail |
| PATCH | `/reports/{id}/status` | Change status and add admin notes |
| DELETE | `/reports/{id}` | Delete a report |
| GET | `/scans` | List scans (filters: `status`, `search`, `skip`, `limit`) |
| GET | `/scans/stats` | Scan totals by outcome and trend |
| GET | `/analytics` | Dashboard chart data |

Report status transitions:

- `pending` → `under_review` or `dismissed`
- `under_review` → `confirmed` or `dismissed`
- `confirmed` and `dismissed` are final

## Tests

With the server running:

```bash
python tests/smoke_e2e.py http://127.0.0.1:8000
```

`python -m tests.eval_register` measures matching accuracy against the labelled photos in `data/eval/`.

## Deployment

Deployed to Render with the Dockerfile in this folder; see [docs/DEPLOY.md](../../docs/DEPLOY.md).
