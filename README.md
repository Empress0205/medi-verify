# MediGuard — Medicine Registration Verification for Tanzania

MediGuard lets anyone photograph a medicine pack and check, in seconds, whether the product is on the **Tanzania Medicines and Medical Devices Authority (TMDA)** register. Suspicious products can be reported to regulators, who review them in an admin dashboard.

A vision model reads the packaging, the extracted details are matched against a live copy of the TMDA register (5,000+ products), and a safety layer flags expired packs, so a registered but expired box is never shown as simply "safe".

## What it does

- **Scan a pack:** take one or more photos (front, back, side panels). The app reads the product name, registration number, manufacturer, batch and expiry date.
- **Check the register:** the result is one of `registered`, `not_found`, `unknown` or `not_medicine`, with a confidence score and the matching TMDA record.
- **Flag safety issues:** expiry and registration validity are shown on top of the verdict without changing it.
- **Report suspicious medicines:** users submit a report with location and pharmacy details.
- **Review in the dashboard:** admins see KPIs, trends, a regional hotspot map, scans and reports, and move each report through `pending → under_review → confirmed / dismissed`.

The app never claims a product is counterfeit. It verifies *registration*; deciding that a product is counterfeit is left to a human reviewer.

## Architecture

```
 Flutter app ──┐                       ┌── Gemini vision (reads the pack)
               ├──► FastAPI backend ───┤
 React admin ──┘    (services/api)     └── TMDA register (synced from the
 dashboard               │                  TMDA public portal into Postgres)
                     PostgreSQL
```

| Directory | What it is | Stack |
| --- | --- | --- |
| [`apps/mobile`](apps/mobile) | Consumer scanning app | Flutter |
| [`apps/dashboard`](apps/dashboard) | Admin dashboard | React, Vite |
| [`services/api`](services/api) | Verification, reports, scans and analytics API | FastAPI, SQLAlchemy (async), PostgreSQL / SQLite |
| [`data`](data) | TMDA register seed and evaluation set | CSV, images |
| [`docs`](docs) | Architecture, roadmap and deployment guide | |

The verification engine sits behind a pluggable interface (`ENGINE=mock` or `ENGINE=gemini`), so the app can run end to end with no API key using the deterministic mock engine.

More detail: [Architecture](docs/ARCHITECTURE.md) · [Roadmap](docs/ROADMAP.md) · [Deployment](docs/DEPLOY.md)

## Run locally

**Backend**

```bash
cd services/api
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env               # set ENGINE=gemini and GEMINI_API_KEY for real scans
uvicorn main:app --reload
```

API docs are served at <http://localhost:8000/docs>.

**Dashboard**

```bash
cd apps/dashboard
npm install
npm run dev                        # uses VITE_API_BASE_URL, default http://localhost:8000
```

**Mobile app**

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator
```

## Deployment

The backend and a Postgres database deploy to Render from [`render.yaml`](render.yaml) using the Docker image in `services/api`. See [docs/DEPLOY.md](docs/DEPLOY.md).

## Tech stack

Python · FastAPI · SQLAlchemy · PostgreSQL · Google Gemini · Flutter · React · Vite · Docker · Render
