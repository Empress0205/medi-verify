# Shared contracts

The single wire contract shared by all clients:

- **Status enum**: `verified | counterfeit | unknown | not_medicine`
- **Confidence**: `0.0–1.0` float in the API; format to `%` at the UI edge only.
- **`medicine_info` shape**: defined once in `services/api/domain/schemas.py`.

Source of truth is `services/api/domain/` (`enums.py`, `schemas.py`). The
Flutter models (`apps/mobile/lib/models/`) and the React dashboard types must
mirror these. Ideally generate the TS/Dart types from the FastAPI OpenAPI schema
so they can never drift.

## Frozen artifact

`openapi.json` in this folder is the machine-readable contract, exported from
the live app. Regenerate after any schema change:

```
cd services/api && ./.venv/Scripts/python.exe -c \
  "import json; from main import app; \
   json.dump(app.openapi(), open('../../packages/contracts/openapi.json','w'), indent=2)"
```

Locked in the current export:
- `ScanStatus` = verified | counterfeit | unknown | not_medicine
- `ReportStatus` = pending | under_review | confirmed | dismissed
- `confidence_score` / `confidence` = number in **[0.0, 1.0]** (422 on breach)
