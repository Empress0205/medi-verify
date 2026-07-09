from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import re

# Our modules
from database import db
from ocr_processor import perform_ocr
from llm_extractor import extract_fields_with_llm
from matcher import match_against_tmda

app = FastAPI(
    title="TMDA Medicine Verifier API",
    description="OCR + LLM based medicine verification against TMDA",
    version="1.2.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def clean_ocr_text(text: str) -> str:
    """
    Clean OCR output and re-insert important line breaks.
    This helps the LLM correctly detect Batch/MFG/EXP fields.
    """
    if not text:
        return ""

    # Normalize quotes and remove weird symbols
    text = text.replace("’", "'").replace("“", '"').replace("”", '"')

    # Remove non-ascii junk characters
    text = re.sub(r"[^\x00-\x7F]+", " ", text)

    # Add line breaks for important keywords
    keywords = [
        "FORMULA",
        "Batch",
        "Batch No",
        "Batch#",
        "LOT",
        "Lot No",
        "Mfg",
        "MFD",
        "Mfd",
        "Manufactured",
        "Exp",
        "EXP",
        "Expiry",
        "Expires",
        "Manufactured by",
        "Marketed by",
        "REGAL",
        "PHARMACEUTICALS"
    ]

    for k in keywords:
        text = text.replace(k, f"\n{k}")

    # Collapse multiple spaces but keep line breaks
    text = re.sub(r"[ \t]+", " ", text)

    # Clean multiple newlines
    text = re.sub(r"\n+", "\n", text)

    return text.strip()


@app.get("/health")
async def health():
    return {"status": "ok", "records": len(db)}


@app.post("/verify/")
async def verify_medicine(file: UploadFile = File(...)):
    file_location = f"temp_{file.filename}"

    try:
        # Save uploaded image
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # 1. OCR
        ocr_lines = perform_ocr(file_location)

        # 🚨 GUARD 1: No OCR detected
        if not ocr_lines:
            return {
                "success": False,
                "status": "invalid",
                "message": "No readable text found in image",
                "confidence_score": 0.0
            }

        # ✅ IMPORTANT FIX: Preserve line breaks instead of joining everything into one sentence
        raw_text = "\n".join(
            row["detected_text"]
            for row in ocr_lines
            if row.get("detected_text")
        ).strip()

        # Clean OCR output for better LLM extraction
        raw_text = clean_ocr_text(raw_text)

        # 🚨 GUARD 2: Empty text after join
        if not raw_text:
            return {
                "success": False,
                "status": "invalid",
                "message": "Image does not contain readable text",
                "confidence_score": 0.0
            }

        # 🚨 GUARD 3: Basic medicine keyword check
        keywords = ["tablet", "capsule", "mg", "ml", "syrup", "bp", "pharma", "exp", "mfg", "batch"]
        if not any(k.lower() in raw_text.lower() for k in keywords):
            return {
                "success": False,
                "status": "invalid",
                "message": "Image does not appear to contain medicine packaging",
                "confidence_score": 0.0,
                "raw_text": raw_text
            }

        # 2. LLM Extraction
        details = extract_fields_with_llm(raw_text)

        # 🚨 GUARD 4: No meaningful extraction
        if not details or not details.get("medicine_name"):
            return {
                "success": False,
                "status": "invalid",
                "message": "Could not extract medicine details",
                "confidence_score": 0.0,
                "raw_text": raw_text
            }

        # 3. Match against TMDA
        status, confidence_score, matched_row, match_method = match_against_tmda(details)

        db_info = {}
        if matched_row is not None:
            db_info = {
                "brand_name": str(matched_row.get('Brand_Name', '')),
                "certificate_number": str(matched_row.get('Certificate_Number', '')),
                "manufacturer": str(matched_row.get('Manufacturer', '')),
                "registration_status": str(matched_row.get('Registration_Status', '')),
            }

        extracted_fields_table = [
            {"field": "Medicine Name", "value": details.get("medicine_name", "Not on label")},
            {"field": "Reg. No. (Tanzania)", "value": details.get("reg_no_tanzania", "Not on label")},
            {"field": "Batch Number", "value": details.get("batch_number", "Not on label")},
            {"field": "Manufacture Date", "value": details.get("manufacture_date", "Not on label")},
            {"field": "Expiry Date", "value": details.get("expiry_date", "Not on label")},
            {"field": "Manufacturer", "value": details.get("manufacturer", "Not on label")},
            {"field": "Verification Status", "value": status.upper()},
            {"field": "Confidence Score", "value": f"{confidence_score:.0%}"},
            {"field": "Matched By", "value": match_method},
        ]

        medicine_info = {
            "name": details.get("medicine_name", "Not on label"),
            "manufacturer": details.get("manufacturer", "Not on label"),
            "batchNumber": details.get("batch_number", "Not on label"),
            "manufactureDate": details.get("manufacture_date", "Not on label"),
            "expiryDate": details.get("expiry_date", "Not on label"),
            "regNoTanzania": details.get("reg_no_tanzania", "Not on label"),
        }

        return {
            "success": True,
            "status": status,
            "confidence_score": confidence_score,
            "match_method": match_method,
            "message": "Verification complete",
            "extracted_fields_table": extracted_fields_table,
            "tmda_database_match": db_info,
            "raw_text": raw_text,
            "medicine_info": medicine_info
        }

    except Exception as e:
        return {
            "success": False,
            "status": "error",
            "message": f"Processing failed: {str(e)}",
            "confidence_score": 0.0
        }

    finally:
        if os.path.exists(file_location):
            try:
                os.remove(file_location)
            except:
                pass