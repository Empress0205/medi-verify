"""
Mock engine — a deterministic field extractor for dev/demo with no API key.

Same image always yields the same fields. Most samples are real TMDA-registered
products (so the matcher returns "registered"); a couple are invented (so it
returns "not_found"); ~8% simulate a non-medicine photo.
"""
from __future__ import annotations
import hashlib
import random
from typing import Sequence

from domain.schemas import ExtractedFields
from infra.engine.base import Photo

# Mostly real, register-listed names so the matcher can find them.
_SAMPLES = [
    {"medicine_name": "Amoxicillin", "strength": "500mg", "manufacturer": "Shelys Pharmaceuticals"},
    {"medicine_name": "Paracetamol", "strength": "500mg", "manufacturer": "Dawa Limited"},
    {"medicine_name": "Augmentin", "strength": "625mg", "manufacturer": "GSK"},
    {"medicine_name": "Metformin", "strength": "500mg", "manufacturer": "Universal Corporation"},
    {"medicine_name": "Doxyzen", "strength": "100mg", "manufacturer": "Zenufa Laboratories Ltd",
     "reg_no": "TAN 22 HM 0470"},
    # Not on the register — should resolve to not_found:
    {"medicine_name": "Zynofil Forte", "strength": "250mg", "manufacturer": "Acme Pharma"},
]


class MockEngine:
    async def extract(self, photos: Sequence[Photo]) -> ExtractedFields:
        if not photos:
            raise ValueError("no photos supplied")

        seed = int(hashlib.md5(photos[0][0][:2048]).hexdigest(), 16)
        rng = random.Random(seed)

        if rng.random() < 0.08:
            return ExtractedFields(is_medicine=False)

        s = rng.choice(_SAMPLES)

        # Mirror the real world: the registration number and the expiry are
        # usually printed on a panel OTHER than the front, so they only turn up
        # once a second photo of the pack is supplied. This makes the adaptive
        # "take another photo" flow exercisable without burning API quota.
        has_other_panel = len(photos) > 1

        return ExtractedFields(
            is_medicine=True,
            medicine_name=s["medicine_name"],
            strength=s["strength"],
            manufacturer=s["manufacturer"],
            batch_number=f"BN-{rng.randint(10000, 99999)}" if has_other_panel else None,
            mfg_date="01/2024" if has_other_panel else None,
            expiry_date="01/2027" if has_other_panel else None,
            reg_no=s.get("reg_no") if has_other_panel else None,
        )
