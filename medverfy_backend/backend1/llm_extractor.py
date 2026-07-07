import json
import re

try:
    from ollama import chat
except ImportError:
    raise ImportError("❌ ollama not installed. Run: pip install ollama")


def extract_fields_with_llm(raw_text: str) -> dict:
    prompt = f"""You are an expert at reading medicine packaging labels from Tanzania.
Your job is to extract exactly 6 fields from the OCR text below.

=== FIELD DEFINITIONS ===

1. medicine_name
   - The drug name + strength (e.g. "Amoxicillin 500mg", "Paracetamol 500mg Tablets")
   - Include full composition if it is a combination drug (e.g. "Ampicillin 250mg + Cloxacillin 250mg")
   - DO NOT put manufacturer names, registration numbers, or dates here

2. reg_no_tanzania
   - Tanzania registration number / certificate number / TMDA number
   - Usually labelled as: "TMDA", "TFDA", "Reg No", "Certificate No", "Registration No"
   - Examples: "TZ20H1234", "TFDA 1234", "TMDA-REG-2023-001"
   - If not found use "Not on label"

3. batch_number
   - A short alphanumeric production code assigned to a specific manufacturing batch
   - Usually labelled as: "Batch No", "Batch#", "Lot No", "Lot#", "B/N", "BN"
   - Examples: "B12345", "LOT2024A", "A0123B", "2024XY01"
   - DO NOT confuse with registration numbers (those start with TFDA, TZ, PPB, NAFDAC, or contain REG)
   - If not found, use null (not a string)

4. manufacture_date
   - The date the medicine was manufactured
   - Usually labelled as: "MFD", "MFG", "Mfd.", "Manufactured", "Date of Manufacture"
   - Keep the original format (e.g. "01/2024", "Jan 2024", "2024-01")
   - DO NOT put expiry date here

5. expiry_date
   - The date the medicine expires
   - Usually labelled as: "EXP", "Expiry", "Expires", "Use Before", "Best Before", "BB"
   - Keep the original format (e.g. "06/2026", "Jun 2026", "2026-06")
   - DO NOT put manufacture date here

6. manufacturer
   - The name of the company that made the medicine
   - Usually labelled as: "Manufactured by", "Mfd by", "Marketed by"
   - Examples: "GSK", "Dawa Limited", "Shelys Pharmaceuticals"
   - DO NOT put distributor, importer, or registration authority names here

=== IMPORTANT RULES ===
- If a field is not clearly present in the text, use exactly: "Not on label"
- For batch_number specifically: if not found, use null
- DO NOT guess or infer values that are not written
- Return ONLY valid JSON, no extra text, no markdown

=== OUTPUT FORMAT ===
{{
  "medicine_name": "...",
  "reg_no_tanzania": "...",
  "batch_number": null,
  "manufacture_date": "...",
  "expiry_date": "...",
  "manufacturer": "..."
}}

=== OCR TEXT ===
{raw_text}

JSON:"""

    try:
        response = chat(
            model='llama3.2',
            messages=[{'role': 'user', 'content': prompt}],
            options={'temperature': 0.0, 'num_ctx': 8192}
        )

        content = response.message.content.strip()

        start = content.find('{')
        end = content.rfind('}') + 1

        if start >= 0 and end > start:
            json_str = content[start:end]
            data = json.loads(json_str)

            # ✅ Force batch_number to be null if model returned "Not on label"
            if isinstance(data.get("batch_number"), str):
                if data["batch_number"].strip().lower() in ["not on label", "none", "null", ""]:
                    data["batch_number"] = None

            # Prevent registration number being mistaken as batch
            if _looks_like_reg_number(data.get("batch_number")):
                data["batch_number"] = None

            return data

    except Exception as e:
        print(f"⚠️ LLM error: {e}")

    return get_default_fields()


def _looks_like_reg_number(value) -> bool:
    """Detect if a value is a registration/certificate number, not a batch number."""
    if not value:
        return False

    patterns = [
        r"^(TFDA|TZ|PPB|NAFDAC|REG|CERT|NR)[\/\-\s]",
        r"[\/\-][A-Z]{2,4}[\/\-]\d{4}",
        r"\d{4,}\/[A-Z]{2,}\/\d{4}",
    ]

    for pattern in patterns:
        if re.search(pattern, str(value), re.IGNORECASE):
            return True

    return False


def get_default_fields():
    return {
        "medicine_name": "Not on label",
        "reg_no_tanzania": "Not on label",
        "batch_number": None,
        "manufacture_date": "Not on label",
        "expiry_date": "Not on label",
        "manufacturer": "Not on label"
    }