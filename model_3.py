# ============================================
# ✅ KoBERT 학습 안정화 + 라벨별 성능 출력 + Null 처리 (CPU 전용)
# ============================================

import torch
from torch.utils.data import Dataset, DataLoader
from transformers import BertForSequenceClassification
from kobert_transformers import get_tokenizer
from torch.optim import AdamW
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score, classification_report
import pandas as pd
from tqdm import tqdm

# ============================================
# 1️⃣ 데이터 로드 및 점검
# ============================================
data_path = r"C:\Users\jiheo\OneDrive\Desktop\emotion_dataset.csv"
df = pd.read_csv(data_path)

print(f" 데이터셋 크기: {len(df)}")
print(f" 컬럼: {df.columns.tolist()}")
print(f" label_num 고유값: {sorted(df['label_num'].unique().tolist())}")

# 문자열이면 변환
if df['label_num'].dtype == 'object':
    df['label_num'] = df['label_num'].astype('category').cat.codes
    print(" label_num이 문자열이라 변환했습니다 →", sorted(df['label_num'].unique().tolist()))

# ============================================
#  라벨 분포 출력 + Null 처리
# ============================================
label_names = {
    0: "기쁨", 1: "당황", 2: "분노", 3: "불안", 4: "상처",
    5: "슬픔", 6: "중립", 7: "역겨움", 8: "공포", 9: "놀람"
}

print("\n 라벨 분포:")
label_counts = df['label_num'].value_counts().sort_index()
for label_id, label_name in label_names.items():
    count = label_counts.get(label_id, 0)
    print(f"{label_name} ({label_id}): {count}개")
    
# 데이터가 없는 라벨 제거
valid_labels = label_counts[label_counts > 0].index.tolist()
df = df[df['label_num'].isin(valid_labels)].reset_index(drop=True)
print(f"\n Null 처리 후 사용되는 라벨: {valid_labels}")

# ============================================
# 2️⃣ 데이터 분리
# ============================================
train_texts, test_texts, train_labels, test_labels = train_test_split(
    df['text'].tolist(),
    df['label_num'].tolist(),
    test_size=0.2,
    random_state=42,
    stratify=df['label_num']
)

# ============================================
# 3️⃣ 토크나이저
# ============================================
tokenizer = get_tokenizer()
print(f"사용 중인 토크나이저: {tokenizer.__class__.__name__}")

max_len = 128
train_encodings = tokenizer(train_texts, max_length=max_len, truncation=True, padding=True)
test_encodings = tokenizer(test_texts, max_length=max_len, truncation=True, padding=True)

# ============================================
# 4️⃣ Dataset 정의
# ============================================
class EmotionDataset(Dataset):
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        item = {key: torch.tensor(val[idx]) for key, val in self.encodings.items()}
        item['labels'] = torch.tensor(self.labels[idx])
        return item

train_dataset = EmotionDataset(train_encodings, train_labels)
test_dataset = EmotionDataset(test_encodings, test_labels)

# ============================================
# 5️⃣ DataLoader
# ============================================
train_loader = DataLoader(train_dataset, batch_size=16, shuffle=True)
test_loader  = DataLoader(test_dataset, batch_size=32, shuffle=False)

# ============================================
# 6️⃣ 모델 및 Optimizer (CPU 전용)
# ============================================
device = torch.device('cpu')  # ✅ 강제로 CPU만 사용
print("GPU 비활성화 → CPU로 학습 실행 중")

model = BertForSequenceClassification.from_pretrained('monologg/kobert', num_labels=len(valid_labels))
model.to(device)

print(f"모델 로드 확인: {model.config._name_or_path}")
optimizer = AdamW(model.parameters(), lr=2e-5)

# ============================================
# 7️⃣ Metric 함수
# ============================================
def compute_metrics(preds, labels):
    acc = accuracy_score(labels, preds)
    f1 = f1_score(labels, preds, average='macro', zero_division=0)
    prec = precision_score(labels, preds, average='macro', zero_division=0)
    rec = recall_score(labels, preds, average='macro', zero_division=0)
    return acc, f1, prec, rec

# ============================================
# 8️⃣ 학습 루프
# ============================================
epochs = 10
for epoch in range(epochs):
    print(f"\n===== Epoch {epoch+1}/{epochs} =====")

    # ---- 학습 단계 ----
    model.train()
    total_loss = 0
    train_bar = tqdm(train_loader, desc="Training", leave=False)

    for batch in train_bar:
        optimizer.zero_grad()
        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['labels'].to(device)

        outputs = model(input_ids, attention_mask=attention_mask, labels=labels)
        loss = outputs.loss
        loss.backward()
        optimizer.step()

        total_loss += loss.item()
        train_bar.set_postfix(loss=f"{loss.item():.4f}")

    avg_loss = total_loss / len(train_loader)
    print(f"Training Loss: {avg_loss:.4f}")

    # ---- 평가 단계 ----
    model.eval()
    all_preds, all_labels = [], []
    eval_bar = tqdm(test_loader, desc="Evaluating", leave=False)

    with torch.no_grad():
        for batch in eval_bar:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['labels'].to(device)

            outputs = model(input_ids, attention_mask=attention_mask)
            preds = outputs.logits.argmax(dim=1)
            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    acc, f1, prec, rec = compute_metrics(all_preds, all_labels)
    print(f"Eval | Acc: {acc:.4f} | F1: {f1:.4f} | Precision: {prec:.4f} | Recall: {rec:.4f}") 

    # ---- 라벨별 정확도 ----
    print("\n 라벨별 정확도:")
    report = classification_report(
        all_labels,
        all_preds,
        target_names=[label_names[i] for i in valid_labels],
        zero_division=0
    )
    print(report)
