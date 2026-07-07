from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from typing import List

app = FastAPI()

# Allow frontend (dashboard + mobile)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Temporary storage
reports = []

# Data model
class Report(BaseModel):
    medicine_name: str
    status: str
    confidence: float

# Receive report from mobile app
@app.post("/report")
def create_report(report: Report):
    reports.append(report)
    return {"message": "Report received"}

# Send reports to dashboard
@app.get("/reports")
def get_reports():
    return reports