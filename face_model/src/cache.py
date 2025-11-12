# cache_all_emotions.py
import torch
from torchvision import transforms
from pathlib import Path
from PIL import Image
from tqdm.notebook import tqdm

# =======================
# 경로 설정
# =======================
PROCESSED_DIR = Path("C:/AI_emotion/processed_data")
CACHE_DIR = Path("C:/AI_emotion/cache/all_batches")
CACHE_DIR.mkdir(parents=True, exist_ok=True)

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
BATCH_SIZE = 500  # 한 번에 처리할 이미지 수

preprocess = transforms.Compose([
    transforms.Resize((224,224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225])
])

# =======================
# 각 감정 폴더 순회
# =======================
for emotion_dir in PROCESSED_DIR.iterdir():
    if not emotion_dir.is_dir():
        continue
    emotion_name = emotion_dir.name
    img_paths = list(emotion_dir.glob("*.jpg")) + list(emotion_dir.glob("*.png"))
    total_images = len(img_paths)
    print(f"\n[{emotion_name}] 총 이미지: {total_images}장")

    # 배치 단위 캐시 생성
    for i in tqdm(range(0, total_images, BATCH_SIZE), desc=f"[{emotion_name}] 캐시 생성", ncols=100):
        batch_paths = img_paths[i:i+BATCH_SIZE]
        batch_tensors = []

        for img_path in batch_paths:
            try:
                img = Image.open(img_path).convert("RGB")
                tensor = preprocess(img).to(DEVICE)
                batch_tensors.append(tensor.cpu())  # CPU로 이동
            except Exception as e:
                print(f"⚠️ 이미지 오류: {img_path} ({e})")
        
        if batch_tensors:
            batch_tensor = torch.stack(batch_tensors)
            batch_file = CACHE_DIR / f"{emotion_name}_batch_{i//BATCH_SIZE + 1}.pt"
            torch.save(batch_tensor, batch_file)
            print(f"✅ [{emotion_name}] 배치 저장: {batch_file} ({batch_tensor.shape[0]}장)")
