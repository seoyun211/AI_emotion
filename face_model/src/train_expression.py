# train_from_batches_jupyter.py
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision.models import efficientnet_b0, EfficientNet_B0_Weights
from torch.utils.data import TensorDataset, ConcatDataset, DataLoader, random_split
from pathlib import Path
import matplotlib.pyplot as plt

# =======================
# 설정
# =======================
CACHE_DIR = Path("C:/AI_emotion/cache/all_batches")
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
TRAIN_BATCH = 64
EPOCHS = 15
LEARNING_RATE = 1e-4

# =======================
# 감정 라벨 맵 (파일명 기준)
# =======================
LABEL_MAP = {
    '기쁨': 0, '당황': 1, '분노': 2, '불안': 3,
    '상처': 4, '슬픔': 5, '중립': 6
}

# =======================
# 캐시 불러오기
# =======================
all_datasets = []

for cache_file in CACHE_DIR.glob("*.pt"):
    try:
        tensor_data = torch.load(cache_file, map_location="cpu")
        emotion_name = cache_file.stem.split("_batch")[0]  # 파일명 앞부분에서 감정 추출
        label = LABEL_MAP[emotion_name]
        labels = torch.full((tensor_data.size(0),), label, dtype=torch.long)
        dataset = TensorDataset(tensor_data, labels)
        all_datasets.append(dataset)
    except Exception as e:
        print(f"❌ 로드 실패: {cache_file.name} ({e})")

if not all_datasets:
    raise RuntimeError("❌ 불러올 캐시가 없습니다.")

full_dataset = ConcatDataset(all_datasets)
print(f"✅ 전체 데이터셋: {len(full_dataset)}장, 클래스 수: {len(LABEL_MAP)}")

# =======================
# train/val split
# =======================
train_size = int(0.8 * len(full_dataset))
val_size = len(full_dataset) - train_size
train_dataset, val_dataset = random_split(full_dataset, [train_size, val_size])

train_loader = DataLoader(train_dataset, batch_size=TRAIN_BATCH, shuffle=True, num_workers=0, pin_memory=True)
val_loader = DataLoader(val_dataset, batch_size=TRAIN_BATCH, shuffle=False, num_workers=0, pin_memory=True)

# =======================
# 모델 정의
# =======================
weights = EfficientNet_B0_Weights.DEFAULT
model = efficientnet_b0(weights=weights)
num_features = model.classifier[1].in_features
model.classifier[1] = nn.Linear(num_features, len(LABEL_MAP))
model = model.to(DEVICE)

criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=LEARNING_RATE)

# =======================
# 학습 루프
# =======================
train_losses, val_losses = [], []
train_accs, val_accs = [], []

for epoch in range(1, EPOCHS+1):
    # --- 학습 ---
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    for inputs, targets in train_loader:
        inputs, targets = inputs.to(DEVICE), targets.to(DEVICE)
        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, targets)
        loss.backward()
        optimizer.step()
        running_loss += loss.item() * inputs.size(0)
        _, predicted = outputs.max(1)
        total += targets.size(0)
        correct += predicted.eq(targets).sum().item()
    train_loss = running_loss / total
    train_acc = correct / total * 100
    train_losses.append(train_loss)
    train_accs.append(train_acc)

    # --- 검증 ---
    model.eval()
    val_loss_total = 0.0
    val_correct = 0
    val_total = 0
    with torch.no_grad():
        for inputs, targets in val_loader:
            inputs, targets = inputs.to(DEVICE), targets.to(DEVICE)
            outputs = model(inputs)
            loss = criterion(outputs, targets)
            val_loss_total += loss.item() * inputs.size(0)
            _, predicted = outputs.max(1)
            val_correct += predicted.eq(targets).sum().item()
            val_total += targets.size(0)
    val_loss = val_loss_total / val_total
    val_acc = val_correct / val_total * 100
    val_losses.append(val_loss)
    val_accs.append(val_acc)

    print(f"Epoch {epoch}/{EPOCHS} | "
          f"Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.2f}% | "
          f"Val Loss: {val_loss:.4f}, Val Acc: {val_acc:.2f}%")

# =======================
# 학습 완료 및 모델 저장
# =======================
MODEL_DIR = Path("C:/AI_emotion/models")
MODEL_DIR.mkdir(parents=True, exist_ok=True)
torch.save(model.state_dict(), MODEL_DIR / "expression_model.pt")
print("✅ 학습 완료 및 모델 저장: expression_model.pt")

# =======================
# 학습/검증 그래프
# =======================
plt.figure(figsize=(12,5))

plt.subplot(1,2,1)
plt.plot(range(1,EPOCHS+1), train_losses, label="Train Loss")
plt.plot(range(1,EPOCHS+1), val_losses, label="Val Loss")
plt.xlabel("Epoch")
plt.ylabel("Loss")
plt.title("Loss Curve")
plt.legend()

plt.subplot(1,2,2)
plt.plot(range(1,EPOCHS+1), train_accs, label="Train Acc")
plt.plot(range(1,EPOCHS+1), val_accs, label="Val Acc")
plt.xlabel("Epoch")
plt.ylabel("Accuracy (%)")
plt.title("Accuracy Curve")
plt.legend()

plt.show()
