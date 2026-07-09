# ocr_processor.py
import cv2
import os
from typing import List, Dict, Any
from paddleocr import PaddleOCR

# Initialize once
ocr = PaddleOCR(
    use_angle_cls=True,
    lang='en',
)

def preprocess_image(image_path: str) -> str:
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Image not found: {image_path}")

    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Failed to read image: {image_path}")

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    denoised = cv2.fastNlMeansDenoising(enhanced, None, h=10)

    pre_path = image_path + "_pre.png"
    cv2.imwrite(pre_path, denoised)
    return pre_path


def perform_ocr(image_path: str) -> List[Dict[str, Any]]:
    pre_path = preprocess_image(image_path)
    try:
        result = ocr.ocr(pre_path, cls=True)
        ocr_lines = []

        if result and result[0]:
            for idx, line in enumerate(result[0]):
                bbox = line[0]
                text_info = line[1]
                text_val = text_info[0]
                conf = round(float(text_info[1]), 4)

                ocr_lines.append({
                    "line": idx + 1,
                    "detected_text": text_val,
                    "confidence": conf,
                    "position": {
                        "top_left": [int(bbox[0][0]), int(bbox[0][1])],
                        "top_right": [int(bbox[1][0]), int(bbox[1][1])],
                        "bottom_right": [int(bbox[2][0]), int(bbox[2][1])],
                        "bottom_left": [int(bbox[3][0]), int(bbox[3][1])],
                    }
                })
        return ocr_lines
    finally:
        if os.path.exists(pre_path):
            try:
                os.remove(pre_path)
            except:
                pass