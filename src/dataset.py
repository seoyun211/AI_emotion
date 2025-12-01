<<<<<<< HEAD
# -*- coding: utf-8 -*-
import os
import torch
from torch.utils.data import Dataset
from PIL import Image
from torchvision import transforms
from tqdm.notebook import tqdm
from utils import ensure_dir, save_cache, load_cache

class ExpressionDataset(Dataset):
    LABEL_MAP = {
        '기쁨': 0, '당황': 1, '분노': 2, '불안': 3, '상처': 4,
        '슬픔': 5, '중립': 6
    }

    MIN_FACE_RATIO = 0.2  # 최소 얼굴 비율

    def __init__(self, root_dir, cache_file, transform=None):
        self.root_dir = root_dir
        self.cache_file = cache_file
        self.transform = transform or transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
        ])

        ensure_dir(os.path.dirname(self.cache_file))

        # 캐시 로드
        cached = load_cache(self.cache_file)
        if cached:
            self.images, self.labels = cached
        else:
            print("캐시 없음 → 생성 중...")
            self.images, self.labels = self._create_cache()
            save_cache((self.images, self.labels), self.cache_file)

        print(f"데이터셋 로드 완료 ({len(self.images)}장)")

    def _create_cache(self):
        image_tensors, labels = [], []

        # 전체 이미지 수 계산
        total_images = sum(
            len([f for f in os.listdir(os.path.join(self.root_dir, emo))
                 if f.lower().endswith((".jpg", ".png", ".jpeg"))])
            for emo in self.LABEL_MAP
            if os.path.exists(os.path.join(self.root_dir, emo))
        )
        print(f"총 {total_images:,}장 이미지 처리 예정")

        processed = 0

        for emotion, label in self.LABEL_MAP.items():
            emotion_dir = os.path.join(self.root_dir, emotion)
            if not os.path.exists(emotion_dir):
                print(f"폴더 없음, 스킵: {emotion}")
                continue

            files = [f for f in os.listdir(emotion_dir)
                     if f.lower().endswith((".jpg", ".png", ".jpeg"))]

            pbar = tqdm(files, desc=f"{emotion}", ncols=100, unit="img", leave=True)
            for file in files:
                img_path = os.path.join(emotion_dir, file)
                try:
                    img = Image.open(img_path).convert('RGB')
                    w, h = img.size
                    ratio = w / h
                    # 뒤집히거나 이상한 이미지 제외
                    if ratio < 0.5 or ratio > 2.0:
                        continue
                    if min(w, h) / max(w, h) < self.MIN_FACE_RATIO:
                        continue
                    img_tensor = self.transform(img)
                    image_tensors.append(img_tensor)
                    labels.append(label)
                except:
                    continue

                processed += 1
                pbar.set_postfix({
                    "전체 진행률": f"{processed/total_images*100:.2f}%",
                    "총 변환": f"{processed:,}"
                })

            pbar.close()

        images_tensor = torch.stack(image_tensors)
        labels_tensor = torch.tensor(labels, dtype=torch.long)
        print(f"변환 완료: {len(image_tensors):,}장")
        return images_tensor, labels_tensor

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        return self.images[idx], self.labels[idx]
=======
# -*- coding: utf-8 -*-
import os
import torch
from torch.utils.data import Dataset
from PIL import Image
from torchvision import transforms
from tqdm.notebook import tqdm
from utils import ensure_dir, save_cache, load_cache

class ExpressionDataset(Dataset):
    LABEL_MAP = {
        '기쁨': 0, '당황': 1, '분노': 2, '불안': 3, '상처': 4,
        '슬픔': 5, '중립': 6
    }

    MIN_FACE_RATIO = 0.2  # 최소 얼굴 비율

    def __init__(self, root_dir, cache_file, transform=None):
        self.root_dir = root_dir
        self.cache_file = cache_file
        self.transform = transform or transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
        ])

        ensure_dir(os.path.dirname(self.cache_file))

        # 캐시 로드
        cached = load_cache(self.cache_file)
        if cached:
            self.images, self.labels = cached
        else:
            print("캐시 없음 → 생성 중...")
            self.images, self.labels = self._create_cache()
            save_cache((self.images, self.labels), self.cache_file)

        print(f"데이터셋 로드 완료 ({len(self.images)}장)")

    def _create_cache(self):
        image_tensors, labels = [], []

        # 전체 이미지 수 계산
        total_images = sum(
            len([f for f in os.listdir(os.path.join(self.root_dir, emo))
                 if f.lower().endswith((".jpg", ".png", ".jpeg"))])
            for emo in self.LABEL_MAP
            if os.path.exists(os.path.join(self.root_dir, emo))
        )
        print(f"총 {total_images:,}장 이미지 처리 예정")

        processed = 0

        for emotion, label in self.LABEL_MAP.items():
            emotion_dir = os.path.join(self.root_dir, emotion)
            if not os.path.exists(emotion_dir):
                print(f"폴더 없음, 스킵: {emotion}")
                continue

            files = [f for f in os.listdir(emotion_dir)
                     if f.lower().endswith((".jpg", ".png", ".jpeg"))]

            pbar = tqdm(files, desc=f"{emotion}", ncols=100, unit="img", leave=True)
            for file in files:
                img_path = os.path.join(emotion_dir, file)
                try:
                    img = Image.open(img_path).convert('RGB')
                    w, h = img.size
                    ratio = w / h
                    # 뒤집히거나 이상한 이미지 제외
                    if ratio < 0.5 or ratio > 2.0:
                        continue
                    if min(w, h) / max(w, h) < self.MIN_FACE_RATIO:
                        continue
                    img_tensor = self.transform(img)
                    image_tensors.append(img_tensor)
                    labels.append(label)
                except:
                    continue

                processed += 1
                pbar.set_postfix({
                    "전체 진행률": f"{processed/total_images*100:.2f}%",
                    "총 변환": f"{processed:,}"
                })

            pbar.close()

        images_tensor = torch.stack(image_tensors)
        labels_tensor = torch.tensor(labels, dtype=torch.long)
        print(f"변환 완료: {len(image_tensors):,}장")
        return images_tensor, labels_tensor

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        return self.images[idx], self.labels[idx]
>>>>>>> bff150c3597b1bd6ff4c7089c0cfb0a42fb41c46
