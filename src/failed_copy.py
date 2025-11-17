# failed_copy.py
import os
import shutil
from pathlib import Path
from tqdm import tqdm

# =======================
# 경로 설정
# =======================
BASE_DIR = Path("C:/AI_emotion")
RAW_DIR = BASE_DIR / "expression_data"
PROCESSED_DIR = BASE_DIR / "processed_data"
FAILED_DIR = BASE_DIR / "failed_images"
FAILED_DIR.mkdir(parents=True, exist_ok=True)

# =======================
# 감정 폴더 전체 순회
# =======================
for emotion in os.listdir(RAW_DIR):
    raw_emotion_dir = RAW_DIR / emotion
    processed_emotion_dir = PROCESSED_DIR / emotion
    failed_emotion_dir = FAILED_DIR / emotion
    failed_emotion_dir.mkdir(parents=True, exist_ok=True)

    if not raw_emotion_dir.is_dir():
        continue

    raw_files = {f.name for f in raw_emotion_dir.glob("*.*")}
    processed_files = {f.name for f in processed_emotion_dir.glob("*.*")} if processed_emotion_dir.exists() else set()

    # 잘린 폴더에 없는 파일 = 실패 이미지
    failed_files = list(raw_files - processed_files)

    # 진행률 표시하면서 복사
    print(f" {emotion} 처리 중... (총 {len(failed_files)}장)")
    for fname in tqdm(failed_files, desc=f"{emotion}", unit="img"):
        src = raw_emotion_dir / fname
        dst = failed_emotion_dir / fname
        try:
            shutil.copy(src, dst)
        except Exception as e:
            print(f" 복사 실패: {fname} ({e})")

    print(f"✅ {emotion} 완료! 실패 이미지: {len(failed_files)}장 복사됨\n")

print(" 전체 실패 이미지 복사 완료!")
