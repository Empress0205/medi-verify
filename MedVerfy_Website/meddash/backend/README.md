# MediGuard Backend API

FastAPI backend that powers both the Flutter mobile app and the React admin dashboard.

---

## Project structure

```
mediguard_backend/
├── app/
│   ├── main.py                  ← FastAPI app, CORS, router registration
│   ├── core/
│   │   ├── config.py            ← All settings (reads from .env)
│   │   ├── security.py          ← JWT creation/verification
│   │   └── verification.py      ← Medicine image AI engine (mock + real hook)
│   ├── db/
│   │   └── database.py          ← Async SQLAlchemy engine + session
│   ├── models/
│   │   ├── orm.py               ← SQLAlchemy table definitions
│   │   └── schemas.py           ← Pydantic request/response models
│   └── routers/
│       ├── auth.py              ← POST /auth/login, /auth/setup
│       ├── verify.py            ← POST /verify  (Flutter scans)
│       ├── reports.py           ← POST /reports (Flutter submit) + admin CRUD
│       └── analytics.py         ← GET  /analytics (dashboard charts)
├── requirements.txt
├── .env.example
└── README.md
```

---

## Quick start

### 1. Clone and install

```bash
cd mediguard_backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env — at minimum change SECRET_KEY
```

### 3. Run the server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server starts at `http://localhost:8000`  
Interactive docs at `http://localhost:8000/docs`

### 4. Create your first admin account

Call this once — then remove the `/auth/setup` route from `auth.py` in production:

```bash
curl -X POST http://localhost:8000/auth/setup \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "your_strong_password"}'
```

### 5. Log in and get your JWT

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "your_strong_password"}'
```

Copy the `access_token` from the response — paste it into the React dashboard login.

---

## API reference

### Flutter endpoints (no auth required)

| Method | Path        | Description                            |
|--------|-------------|----------------------------------------|
| POST   | `/verify`   | Send medicine image, get AI result     |
| POST   | `/reports`  | Submit a suspicious medicine report    |

#### POST /verify

Send as `multipart/form-data` with field name `image`.

```
Response:
{
  "success": true,
  "status": "verified",          // verified | counterfeit | invalid | unknown
  "confidence_score": 91.2,
  "medicine_info": {
    "name": "Paracetamol 500mg",
    "manufacturer": "Dawa Ltd",
    "batch_number": "BN-2024-0312",
    "expiry_date": "2026-03",
    "scan_time": "2024-11-20T10:00:00Z",
    "active_ingredient": "Paracetamol",
    "dosage": "500mg",
    "warnings": ["Store below 30°C"]
  },
  "message": "Medicine verified against database records."
}
```

#### POST /reports

```json
{
  "scan_id": "optional-uuid-from-scan",
  "medicine_name": "Paracetamol 500mg",
  "manufacturer": "Dawa Ltd",
  "batch_number": "BN-2024-0312",
  "expiry_date": "2026-03",
  "confidence": 91.2,
  "region": "Dar es Salaam",
  "street": "Kariakoo",
  "pharmacy": "Afya Pharmacy",
  "category": "Packaging Issues",
  "description": "Box looks faded, seal broken"
}
```

### Admin endpoints (JWT required — pass as Bearer token)

| Method | Path                       | Description                  |
|--------|----------------------------|------------------------------|
| GET    | `/reports`                 | List reports (filterable)    |
| GET    | `/reports/{id}`            | Single report detail         |
| PATCH  | `/reports/{id}/status`     | Update status + admin notes  |
| DELETE | `/reports/{id}`            | Delete report                |
| GET    | `/analytics`               | All dashboard chart data     |

#### GET /reports — query params

- `status` — `pending` | `under_review` | `confirmed` | `dismissed`
- `region` — partial match, e.g. `Arusha`
- `category` — exact match
- `search` — searches medicine name, report code, pharmacy name
- `skip` / `limit` — pagination

#### PATCH /reports/{id}/status

```json
{
  "status": "under_review",
  "admin_notes": "Sent sample to lab for testing"
}
```

Status transitions allowed:
- `pending` → `under_review` or `dismissed`
- `under_review` → `confirmed` or `dismissed`
- `confirmed` / `dismissed` → no further transitions

---

## Connecting Flutter

In your Flutter `api_service.dart`, point the base URL to this server:

```dart
// Development (emulator)
const String baseUrl = 'http://10.0.2.2:8000';

// Development (physical device on same WiFi)
const String baseUrl = 'http://192.168.x.x:8000';

// Production
const String baseUrl = 'https://api.mediguard.tz';
```

**Verify call:**
```dart
final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/verify'));
request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
final response = await request.send();
```

**Report submission call:**
```dart
await http.post(
  Uri.parse('$baseUrl/reports'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'medicine_name': record.medicineName,
    'manufacturer':  record.manufacturer,
    'batch_number':  record.batchNumber,
    'expiry_date':   record.expiryDate,
    'confidence':    record.confidenceScore,
    'region':        regionCtrl.text,
    'street':        streetCtrl.text,
    'pharmacy':      pharmacyCtrl.text,
    'category':      selectedCategory,
    'description':   descCtrl.text,
  }),
);
```

## Connecting the React dashboard

Replace the mock data fetch in `AdminDashboard.jsx` with:

```js
const API = 'http://localhost:8000';
const token = localStorage.getItem('token'); // after login

// Fetch reports
const res = await fetch(`${API}/reports`, {
  headers: { Authorization: `Bearer ${token}` }
});
const reports = await res.json();

// Fetch analytics
const analytics = await fetch(`${API}/analytics`, {
  headers: { Authorization: `Bearer ${token}` }
}).then(r => r.json());

// Update status
await fetch(`${API}/reports/${id}/status`, {
  method: 'PATCH',
  headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ status: 'under_review' })
});
```

---

## Production checklist

- [ ] Change `SECRET_KEY` in `.env` to a long random string
- [ ] Switch `DATABASE_URL` to PostgreSQL
- [ ] Set `DEBUG=false`
- [ ] Replace `CORS_ORIGINS=["*"]` with exact domain list
- [ ] Remove or protect the `/auth/setup` endpoint
- [ ] Set `USE_REAL_AI=true` and configure your AI model endpoint
- [ ] Deploy behind HTTPS (nginx + certbot, or Railway/Render)