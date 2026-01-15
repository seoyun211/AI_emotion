import torch
import os
from torchvision import transforms
from pathlib import Path
from PIL import Image

data = Path("C:/AI_emotion/processed_data") #데이터 경로(약 4만장)
save_dir = Path("C:/AI_emotion/cache") #캐시파일로 저장/없을시 생성
if not save_dir.exists():
    save_dir.mkdir()

device = "cuda"
batch_size = 500 #메모리에따라 조절

img_tf = transforms.Compose([
    transforms.Resize((224,224)),
    transforms.ToTensor(),    #구글링
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])])

emotions = [d for d in data.iterdir() if d.is_dir()]

for emo_dir in emotions:
    label = emo_dir.name
    files = list(emo_dir.glob("*.jpg")) + list(emo_dir.glob("*.png"))
    print(f"\n>> {label} 스타투 (총 {len(files)}장)")

    for i in range(0, len(files), batch_size):  #500장씩 
        batch_files = files[i : i + batch_size]
        tensors = []

        for f in batch_files:
            try:
                img = Image.open(f).convert("RGB")
                tensors.append(img_tf(img))
            except:
                print(f"오류무시: {f.name}")

        if tensors:
            batch_tensor = torch.stack(tensors)  #텐서합치기
            save_path = save_dir / f"{label}_{i//batch_size}.pt"
            torch.save(batch_tensor, save_path)
            print(f"{save_path.name} 저장")