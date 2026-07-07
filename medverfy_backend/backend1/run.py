import sys
from pathlib import Path
root_dir = Path(__file__).parent.absolute()
sys.path.insert(0, str(root_dir))

import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",  # <-- change here
        port=8000,
        reload=True,
        log_level="info"
    )