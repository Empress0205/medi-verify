# Evaluation set — register verification

Drop **real** photos of medicine packaging here to measure and calibrate the
engine. This is the only way to trust the accuracy numbers — synthetic labels
are too easy and prove nothing.

## Naming

Name each file `<expected>__<label>.jpg`, where `<expected>` is the correct
answer:

| prefix | use for |
|---|---|
| `registered__` | a genuine medicine you know is on the TMDA register |
| `not_found__` | a product not on the register (or a foreign/unregistered pack) |
| `not_medicine__` | anything that isn't medicine packaging (food, a face, a blur) |

Examples: `registered__panadol_box.jpg`, `not_found__herbal_sachet.jpg`,
`not_medicine__water_bottle.jpg`.

Aim for ~15–30 photos across the three classes, ideally with real-world messiness
(glare, angles, blister strips, Swahili/English labels).

## Run

```
cd services/api
./.venv/Scripts/python.exe -m tests.eval_register     # uses ENGINE from .env
```

Watch **`registered` precision** above all: a false "registered" gives false
reassurance about a possibly-fake medicine, so keep it near 100% even if it
means more honest "not found" results.

*(This folder is intentionally in git with only this README; the photos you add
are yours to keep local or commit as a fixture set.)*
