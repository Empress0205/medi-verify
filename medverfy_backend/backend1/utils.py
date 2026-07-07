# app/utils.py
import re
from typing import List, Dict

def split_columns(ocr_lines: List[Dict]):
    if not ocr_lines:
        return [], []
    all_x = [l["position"]["top_left"][0] for l in ocr_lines]
    mid_x = (max(all_x) + min(all_x)) / 2
    left = [l for l in ocr_lines if l["position"]["top_left"][0] < mid_x]
    right = [l for l in ocr_lines if l["position"]["top_left"][0] >= mid_x]
    # Sort both by vertical position
    left = sorted(left, key=lambda l: l["position"]["top_left"][1])
    right = sorted(right, key=lambda l: l["position"]["top_left"][1])
    return left, right

def find_after_label(lines: List[Dict], patterns: List[str], search_range: int = 20) -> str | None:
    texts = [l["detected_text"] for l in lines]
    for i, text in enumerate(texts):
        for pat in patterns:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                after = text[m.end():].strip(" :/()")
                if after and len(after) > 3:
                    return after
                # Look in next lines
                for j in range(i + 1, min(i + search_range, len(texts))):
                    candidate = texts[j].strip()
                    if candidate and len(candidate) > 3:
                        return candidate
    return None