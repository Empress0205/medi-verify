# app/config.py
FIELD_PATTERNS = {
    "reg_no": [
        r'Reg\.?\s*No\.?\s*[:\.]?\s*(TZ\s*\d+\s*[A-Z0-9]+)',
        r'(TAN\s*[\d,\s]*[A-Z0-9]+)',
        r'Tanzania Regn?\.?No\.?\s*[:.]?\s*(TAN[0-9, ]*[A-Z0-9]+)',
    ],
    "batch": [
        r'(?:LOT\s*N[:\.]?|BATCH\s*NO\.?|B\.?\s*NO\.?|Lot No)\s*[:\s]\s*([A-Z]{0,3}\d{3,}[A-Z0-9]*)',
    ],
    "mfg_date": [
        r'MFG\.?\s*(?:DATE)?\s*[:\.]?\s*([A-Z]{3}\.?\s*\d{4}|[0-9]{6,})',
    ],
    "exp_date": [
        r'EXP\.?\s*(?:DATE)?\s*[:\.]?\s*([A-Z]{3}\.?\s*\d{4}|[0-9]{6,})',
    ],
    "manufacturer": [
        r'(Manufactured by|Fabriqué par|Manufacturer)[:\s]*(.+?)(?=\s{2,}|$)',
    ],
    # New: medicine name hints (works for any drug)
    "medicine_name_hints": [
        r'Composition[:\s]*(.+?)(?=\s{2,}|$)',
        r'Active Ingredient[:\s]*(.+?)(?=\s{2,}|$)',
        r'Each (?:capsule|tablet|ml) contains[:\s]*(.+?)(?=\s{2,}|$)',
    ]
}