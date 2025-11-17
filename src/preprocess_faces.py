# preprocess_faces.py
import os
from pathlib import Path
from PIL import Image
from tqdm import tqdm
import mediapipe as mp
import numpy as np

# =======================
# 경로 설정
# =======================
DATA_DIR = Path("C:/AI_emotion/expression_data")
PROCESSED_DIR = Path("C:/AI_emotion/processed_data")
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

# =======================
# Mediapipe 얼굴 탐지
# =======================
mp_face = mp.solutions.face_detection

def crop_face_from_landmarks(image: Image.Image, detection) -> Image.Image:
    """
    Mediapipe detection 결과에서 얼굴 영역 crop
    """
    img_w, img_h = image.size
    bbox = detection.location_data.relative_bounding_box
    x1 = max(int(bbox.xmin * img_w), 0)
    y1 = max(int(bbox.ymin * img_h), 0)
    x2 = min(x1 + int(bbox.width * img_w), img_w)
    y2 = min(y1 + int(bbox.height * img_h), img_h)
    
    return image.crop((x1, y1, x2, y2))

# =======================
# 이미지 처리
# =======================
with mp_face.FaceDetection(model_selection=1, min_detection_confidence=0.5) as face_detector:
    for label_name in os.listdir(DATA_DIR):
        label_dir = DATA_DIR / label_name
        if not label_dir.is_dir():
            continue

        processed_label_dir = PROCESSED_DIR / label_name
        processed_label_dir.mkdir(parents=True, exist_ok=True)

        img_files = list(label_dir.glob("*.*"))
        print(f"Processing {label_name} ({len(img_files)} images)...")
        fail_count = 0

        for img_file in tqdm(img_files, desc=f"{label_name}", unit="img", ncols=100, leave=False):
            try:
                img = Image.open(img_file).convert("RGB")
            except:
                fail_count += 1
                continue

            img_rgb = np.array(img)  # PIL → numpy
            results = face_detector.process(img_rgb)

            if results.detections:
                face_crop = crop_face_from_landmarks(img, results.detections[0])
                save_path = processed_label_dir / img_file.name
                face_crop.save(save_path)
            else:
                fail_count += 1

        print(f"{label_name} 완료! 실패 이미지: {fail_count}/{len(img_files)}")

print(" 얼굴 전처리 완료!")
