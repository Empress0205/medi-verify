# Deploying the MediGuard backend to Render

The **backend** (`services/api`) is the only thing that must be hosted. The
mobile app and dashboard are clients that point at it. This repo ships a
`render.yaml` blueprint that provisions the API **and** a free Postgres in one
step.

## What you do (≈10 minutes)

1. **Make sure the repo is on GitHub** (it is) and this branch is pushed.

2. In Render → **New → Blueprint** → connect this repository.
   Render reads `render.yaml` and shows two things to create:
   - `mediguard-api` (the web service, from `services/api/Dockerfile`)
   - `mediguard-db` (a free Postgres)

3. Render will ask for the two **secret** env vars (marked `sync: false`):
   - **`GEMINI_API_KEY`** → paste your Google AI Studio key.
   - **`ADMIN_PASSWORD`** → choose a strong dashboard admin password.
   (`SECRET_KEY` is auto-generated; `DATABASE_URL` is wired from the DB.)

4. Click **Apply / Deploy**. First build takes a few minutes.

5. When it's live you get a URL like **`https://mediguard-api.onrender.com`**.
   - Check `…/health` → `{"status":"ok"}`
   - Check `…/docs` → the API explorer
   - The TMDA register **auto-seeds on first boot** (~20–30s after start; the
     app is usable immediately, results just fill in once the sync finishes).

That's the backend live. Nothing else is required for it to work.

## Then — point the clients at it (I do this)

- **Mobile app:** rebuild the APK with the URL baked in:
  `flutter build apk --release --dart-define=API_BASE_URL=https://mediguard-api.onrender.com`
  → share/install the resulting APK.
- **Dashboard (optional public link):** set `VITE_API_BASE_URL` to the same URL
  and deploy `apps/dashboard` as a Render **Static Site**
  (build: `npm install && npm run build`, publish dir: `dist`). Or just run it
  locally with `npm run dev`.
- **Admin login** (dashboard): username `admin`, password = the `ADMIN_PASSWORD`
  you set.

## Good to know (free tier)

- The free web service **sleeps after ~15 min idle**; the next request cold-starts
  in ~30–60s. Fine for demos.
- Render's **free Postgres is deleted after ~30 days** — for anything longer,
  upgrade the DB or re-create it (the register re-seeds automatically on boot).
- The register refreshes itself every `REGISTER_SYNC_HOURS` (default 24). To use
  a Render **Cron Job** instead, set `REGISTER_SYNC_HOURS=0` and schedule
  `python -m infra.tmda_sync`.
