"""
Register-verification eval harness — measures how well the CURRENT engine
(ENGINE in .env) + matcher classify real package photos.

Usage:
  1. Drop photos into  data/eval/  named  <expected>__<anything>.jpg
     where <expected> is one of: registered | not_found | not_medicine
     e.g.  registered__panadol_box.jpg   not_found__street_pills.jpg
  2. From services/api:   ./.venv/Scripts/python.exe -m tests.eval_register

It prints per-photo results and two headline numbers:
  * overall accuracy
  * PRECISION on "registered" — of everything we called registered, how many
    truly were. A false "registered" reassures a victim, so this is the number
    to protect; keep it at/near 100% even if it costs some recall.
"""
import asyncio
import glob
import os

from infra.db import AsyncSessionLocal
from infra.engine import matcher
from services.verification_service import get_engine

EVAL_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "data", "eval"))
VALID = {"registered", "not_found", "not_medicine", "unknown"}


async def evaluate():
    files = sorted(
        glob.glob(os.path.join(EVAL_DIR, "*.jpg"))
        + glob.glob(os.path.join(EVAL_DIR, "*.jpeg"))
        + glob.glob(os.path.join(EVAL_DIR, "*.png"))
    )
    if not files:
        print(f"No eval images found in {EVAL_DIR}")
        print("Add photos named  <expected>__<label>.jpg  (expected = registered|not_found|not_medicine)")
        return

    engine = get_engine()
    rows = []
    for f in files:
        expected = os.path.basename(f).split("__")[0].lower()
        if expected not in VALID:
            print(f"  [skip] {os.path.basename(f)} — bad expected prefix")
            continue
        try:
            fields = await engine.extract(open(f, "rb").read(), os.path.basename(f))
            async with AsyncSessionLocal() as db:
                res = await matcher.match(fields, db)
            got = res.status.value
        except Exception as e:
            got = f"ERROR({type(e).__name__})"
        ok = got == expected
        rows.append((expected, got))
        print(f"  [{'ok  ' if ok else 'MISS'}] {os.path.basename(f):44} expected={expected:12} got={got}")

    total = len(rows)
    if not total:
        return
    correct = sum(1 for e, g in rows if e == g)
    called_reg = [(e, g) for e, g in rows if g == "registered"]
    tp = sum(1 for e, g in called_reg if e == "registered")

    print(f"\naccuracy: {correct}/{total} = {correct / total:.0%}")
    if called_reg:
        print(f"'registered' precision: {tp}/{len(called_reg)} = {tp / len(called_reg):.0%}  "
              f"(watch this — a false 'registered' is the dangerous error)")


if __name__ == "__main__":
    asyncio.run(evaluate())
