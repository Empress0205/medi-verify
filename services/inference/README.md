# Inference service (optional — Phase 2)

A standalone deployment of the heavy verification engine (PaddleOCR + Ollama +
TMDA matcher), exposing a single `POST /verify` that the main API's
`RemoteEngine` calls.

Only stand this up if **Decision 1** picks the split-service model. Until then
the same engine code lives in `services/api/infra/engine/` and runs in-process.

The engine source has been ported to `services/api/infra/engine/` (`ocr.py`,
`llm.py`, `matcher.py`, `tmda_loader.py`). If split out, move those here.
