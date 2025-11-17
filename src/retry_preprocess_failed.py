# retry_preprocess_failed.py
import os
from pathlib import Path
from PIL import Image, ImageOps
from tqdm import tqdm
import mediapipe as mp
import numpy as np
import shutil

# =======================
# 경로 설정
# =======================
DATA_DIR = Path("C:/AI_emotion/failed_images")
PROCESSED_DIR = Path("C:/AI_emotion/processed_data")
FAILED_DIR = Path("C:/AI_emotion/retry_failed")

PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
FAILED_DIR.mkdir(parents=True, exist_ok=True)

# =======================
# Mediapipe 얼굴 탐지
# =======================
mp_face = mp.solutions.face_detection

def crop_face_from_landmarks(image: Image.Image, detection) -> Image.Image:
    img_w, img_h = image.size
    bbox = detection.location_data.relative_bounding_box
    x1 = max(int(bbox.xmin * img_w), 0)
    y1 = max(int(bbox.ymin * img_h), 0)
    x2 = min(x1 + int(bbox.width * img_w), img_w)
    y2 = min(y1 + int(bbox.height * img_h), img_h)
    return image.crop((x1, y1, x2, y2))

MIN_FACE_SIZE = 50  # 최소 얼굴 크기(px)

with mp_face.FaceDetection(model_selection=1, min_detection_confidence=0.5) as face_detector:
    for label_name in os.listdir(DATA_DIR):
        label_dir = DATA_DIR / label_name
        if not label_dir.is_dir():
            continue

        processed_label_dir = PROCESSED_DIR / label_name
        processed_label_dir.mkdir(parents=True, exist_ok=True)

        failed_label_dir = FAILED_DIR / label_name
        failed_label_dir.mkdir(parents=True, exist_ok=True)

        img_files = list(label_dir.glob("*.*"))
        fail_count = 0

        print(f"♻️ 재처리 중: {label_name} ({len(img_files)}장)")
        for img_file in tqdm(img_files, desc=f"{label_name}", unit="img", ncols=120, leave=True, ascii=True):
            try:
                img = Image.open(img_file).convert("RGB")
                img = ImageOps.exif_transpose(img)  # 뒤집힘 보정
            except:
                fail_count += 1
                shutil.copy(img_file, failed_label_dir / img_file.name)
                continue

            img_rgb = np.array(img)
            results = face_detector.process(img_rgb)

            if results.detections:
                bbox = results.detections[0].location_data.relative_bounding_box
                face_w = int(bbox.width * img.width)
                face_h = int(bbox.height * img.height)

                if face_w < MIN_FACE_SIZE or face_h < MIN_FACE_SIZE:
                    fail_count += 1
                    shutil.copy(img_file, failed_label_dir / img_file.name)
                    continue

                face_crop = crop_face_from_landmarks(img, results.detections[0])
                save_path = processed_label_dir / img_file.name
                face_crop.save(save_path)
            else:
                fail_count += 1
                shutil.copy(img_file, failed_label_dir / img_file.name)

        print(f"{label_name} 완료! 실패 이미지: {fail_count}/{len(img_files)}\n")

print("✅ 얼굴 재전처리 완료! 실패 이미지는 retry_failed 폴더 확인")
