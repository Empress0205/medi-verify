import re
from difflib import SequenceMatcher
from typing import Dict, Tuple, Optional, List
import pandas as pd

from database import db


def match_against_tmda(details: Dict[str, str]) -> Tuple[str, float, Optional[pd.Series], str]:
    """
    Match extracted medicine details against the TMDA database.

    Returns:
        Tuple: (status, confidence_score, matched_row, match_method)
        - status: "verified" | "unverified" | "counterfeit"
        - confidence_score: 0.0 to 1.0
        - matched_row: pandas Series or None
        - match_method: description of how the match was made
    """

    reg_no_raw = details.get("reg_no_tanzania", "")
    reg_no = re.sub(r'[^A-Z0-9]', '', str(reg_no_raw).upper())

    med_name = str(details.get("medicine_name", "")).upper().strip()
    mfr_name = str(details.get("manufacturer", "")).upper().strip()

    # ====================== STRATEGY 1: REGISTRATION NUMBER ======================
    if reg_no and reg_no not in ("NOTONLABEL", "NOTONLABEL") and len(reg_no) >= 5:
        cert_clean = db['Certificate_Number'].astype(str).str.replace(r'[^A-Z0-9]', '', regex=True)

        hits = db[cert_clean == reg_no]
        if not hits.empty:
            return _threshold_gate("verified", 0.97, hits.iloc[0], "Registration Number (Exact)")

        hits = db[cert_clean.str.contains(reg_no, na=False, case=False)]
        if not hits.empty:
            return _threshold_gate("verified", 0.94, hits.iloc[0], "Registration Number (Partial)")

    # ====================== STRATEGY 2: MEDICINE NAME + MANUFACTURER ======================
    if med_name and len(med_name) > 4:
        ingredients = _extract_ingredients(med_name)

        best_score: float = 0.0
        best_row: Optional[pd.Series] = None
        best_method: str = ""

        for _, row in db.iterrows():
            brand = str(row.get('Brand_Name', '')).upper()
            generic = str(row.get('Generic_Name', '')).upper()
            active = str(row.get('Active_Ingredients', '')).upper()
            mfr_db = str(row.get('Manufacturer', '')).upper()

            name_score = _calculate_name_score(ingredients, brand, generic, active)

            mfr_score = (
                SequenceMatcher(None, mfr_name, mfr_db).ratio()
                if mfr_name and mfr_name not in ("NOT ON LABEL", "NOTONLABEL", "")
                else 0.0
            )

            combined_score = name_score * 0.70 + mfr_score * 0.30

            if combined_score > best_score:
                best_score = combined_score
                best_row = row
                best_method = "Name + Manufacturer" if mfr_score > 0.5 else "Medicine Name"

        if best_row is not None:
            return _decide_match_status(best_score, best_row, best_method)

    return "counterfeit", 0.10, None, "No matching record found"


# ====================== HELPER FUNCTIONS ======================

def _threshold_gate(
    status: str,
    confidence: float,
    row: Optional[pd.Series],
    method: str
) -> Tuple[str, float, Optional[pd.Series], str]:
    if confidence < 0.70:
        return "counterfeit", confidence, None, "Low confidence — no reliable match found"
    return status, confidence, row, method


def _extract_ingredients(med_name: str) -> List[str]:
    parts = re.split(r'\s*\+\s*', med_name)

    ingredients = []
    for part in parts:
        cleaned = re.split(
            r'\s+(TRIHYDRATE|SODIQUE|SODIUM|HYDROCHLORIDE|BP|USP|EP|EQUIVALENT|TABLET|CAPSULE)',
            part.strip()
        )[0].strip()

        if len(cleaned) > 3:
            ingredients.append(cleaned)

    return ingredients


def _calculate_name_score(ingredients: List[str], brand: str, generic: str, active: str) -> float:
    if not ingredients:
        return 0.0

    name_score = 0.0
    for ing in ingredients:
        ing_score = max(
            SequenceMatcher(None, ing, brand).ratio(),
            SequenceMatcher(None, ing, generic).ratio(),
            SequenceMatcher(None, ing, active).ratio(),
            1.0 if (ing in brand or brand in ing) else 0.0,
            1.0 if (ing in generic or generic in ing) else 0.0,
            1.0 if (ing in active or active in ing) else 0.0,
        )
        name_score = max(name_score, ing_score)

    return name_score


def _decide_match_status(
    best_score: float,
    best_row: pd.Series,
    best_method: str
) -> Tuple[str, float, pd.Series, str]:
    if best_score >= 0.75:
        confidence = min(0.93, 0.60 + best_score * 0.35)
        return _threshold_gate("verified", confidence, best_row, best_method)

    elif best_score >= 0.50:
        confidence = 0.50 + best_score * 0.20
        return _threshold_gate("verified", confidence, best_row, f"{best_method} (moderate)")

    elif best_score >= 0.35:
        return _threshold_gate("unverified", best_score * 0.80, best_row, f"Weak match ({best_method})")

    else:
        return "counterfeit", 0.10, None, "No matching record found"