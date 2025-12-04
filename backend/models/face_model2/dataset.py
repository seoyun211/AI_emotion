import os
import torch
from PIL import Image
from torch.utils.data import Dataset
from src.preprocess import get_transforms

class ExpressionDataset(Dataset):
    def __init__(self, root_dir, cache_file, split='train'):
        self.root_dir = root_dir
        self.cache_file = cache_file
        self.transform = get_transforms(split)

        if os.path.exists(cache_file):
            print("✅ 캐시 로드:", cache_file)
            self.data, self.labels = torch.load(cache_file)
        else:
            print("⚡ 캐시 생성 중...")
            self.data, self.labels = [], []
            for label, emotion in enumerate(sorted(os.listdir(root_dir))):
                emotion_dir = os.path.join(root_dir, emotion)
                if not os.path.isdir(emotion_dir):
                    continue
                for img_name in os.listdir(emotion_dir):
                    img_path = os.path.join(emotion_dir, img_name)
                    if img_name.lower().endswith(('.png', '.jpg', '.jpeg')):
                        image = Image.open(img_path).convert('RGB')
                        image = self.transform(image)
                        self.data.append(image)
                        self.labels.append(label)
            self.data = torch.stack(self.data)
            self.labels = torch.tensor(self.labels)
            torch.save((self.data, self.labels), cache_file)
            print("✅ 캐시 생성 완료:", cache_file)

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        return self.data[idx], self.labels[idx]
