"""Phase 3 end-to-end test against a running server (avoids bash quoting)."""
import io, sys
import httpx
from PIL import Image

B = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8131"

def img_bytes(shade):
    buf = io.BytesIO()
    Image.new("RGB", (64, 64), (shade, shade, shade)).save(buf, "JPEG")
    return buf.getvalue()

ok = True
def check(label, cond, extra=""):
    global ok
    ok = ok and cond
    print(f"  [{'PASS' if cond else 'FAIL'}] {label} {extra}")

with httpx.Client(base_url=B, timeout=30) as c:
    # 1. verify -> persists scan, returns scan_id
    r = c.post("/verify", files={"image": ("t.jpg", img_bytes(123), "image/jpeg")})
    v = r.json()
    check("POST /verify 200", r.status_code == 200, f"status={v.get('status')} conf={v.get('confidence_score')}")
    scan_id = v.get("scan_id")
    check("verify returns scan_id", bool(scan_id), f"scan_id={scan_id}")
    check("confidence in 0..1", 0.0 <= v.get("confidence_score", -1) <= 1.0)

    # 2. public report submit with scan_id link
    r = c.post("/reports", json={
        "scan_id": scan_id, "medicine_name": "Coartem", "manufacturer": "Novartis",
        "batch_number": "B9", "expiry_date": "2027-01", "confidence": 0.88,
        "region": "Dodoma", "street": "S", "pharmacy": "Zawadi Pharmacy",
        "category": "Suspicious Source",
    })
    check("POST /reports (public) 201", r.status_code == 201, f"code={r.json().get('report_code')}")

    # 3/4. admin endpoints without token -> 401
    check("GET /reports no token -> 401", c.get("/reports").status_code == 401)
    check("GET /analytics no token -> 401", c.get("/analytics").status_code == 401)
    check("DELETE /reports/x no token -> 401", c.delete("/reports/x").status_code == 401)

    # 5. login
    r = c.post("/auth/login", json={"username": "admin", "password": "admin123"})
    check("POST /auth/login 200", r.status_code == 200)
    tok = r.json().get("access_token", "")
    H = {"Authorization": f"Bearer {tok}"}
    check("bad password -> 401",
          c.post("/auth/login", json={"username": "admin", "password": "nope"}).status_code == 401)

    # 6. list with token
    r = c.get("/reports", headers=H)
    rows = r.json()
    check("GET /reports with token 200", r.status_code == 200, f"count={len(rows)}")
    check("report linked to scan", rows and rows[0].get("scan_id") == scan_id)
    rid = rows[0]["id"]

    # 7. workflow transition pending -> under_review, then illegal jump
    r = c.patch(f"/reports/{rid}/status", headers=H, json={"status": "under_review", "admin_notes": "reviewing"})
    check("PATCH -> under_review 200", r.status_code == 200, f"status={r.json().get('status')}")
    r2 = c.patch(f"/reports/{rid}/status", headers=H, json={"status": "pending"})
    check("illegal transition rejected (400)", r2.status_code == 400, f"-> {r2.status_code}")

    # 8. analytics with token
    r = c.get("/analytics", headers=H)
    a = r.json()
    check("GET /analytics with token 200", r.status_code == 200)
    check("trend has 6 buckets", len(a.get("trend", [])) == 6, f"months={[t['month'] for t in a['trend']]}")
    check("avg_confidence in 0..1", 0.0 <= a.get("avg_confidence", -1) <= 1.0, f"avg={a.get('avg_confidence')}")
    check("under_review count = 1", a["stats"]["under_review"] == 1, f"stats={a['stats']}")

print("RESULT:", "ALL PASS" if ok else "FAILURES ABOVE")
sys.exit(0 if ok else 1)
