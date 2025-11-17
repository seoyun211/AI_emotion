import torch
from torch.utils.data import Dataset, DataLoader
from transformers import BertForSequenceClassification
from kobert_transformers import get_tokenizer
from torch.optim import AdamW
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
import pandas as pd
from tqdm import tqdm

data_path = r"C:\Users\jiheo\OneDrive\Desktop\emotion_dataset.csv"
df = pd.read_csv(data_path)

print(f" 데이터셋 크기: {len(df)}")
print(f" 컬럼: {df.columns.tolist()}")
print(f" label_num 고유값: {sorted(df['label_num'].unique().tolist())}")

# label이 문자열이면 숫자로 변환
if df['label_num'].dtype == 'object':
    df['label_num'] = df['label_num'].astype('category').cat.codes
    print(" label_num이 문자열이라 변환했습니다 →", sorted(df['label_num'].unique().tolist()))

train_texts, test_texts, train_labels, test_labels = train_test_split(
    df['text'].tolist(),
    df['label_num'].tolist(),
    test_size=0.2,
    random_state=42,
    stratify=df['label_num']
)

tokenizer = get_tokenizer()
print(f" 사용 중인 토크나이저: {tokenizer.__class__.__name__}")

max_len = 128
train_encodings = tokenizer(train_texts, max_length=max_len, truncation=True, padding=True)
test_encodings = tokenizer(test_texts, max_length=max_len, truncation=True, padding=True)

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

train_loader = DataLoader(train_dataset, batch_size=16, shuffle=True)
test_loader  = DataLoader(test_dataset, batch_size=32, shuffle=False)

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = BertForSequenceClassification.from_pretrained('monologg/kobert', num_labels=len(set(df['label_num'])))
model.to(device)

print(f" 모델 로드 확인: {model.config._name_or_path}")
optimizer = AdamW(model.parameters(), lr=2e-5) 

def compute_metrics(preds, labels):
    acc = accuracy_score(labels, preds)
    f1 = f1_score(labels, preds, average='macro', zero_division=0)
    precision = precision_score(labels, preds, average='macro', zero_division=0)
    recall = recall_score(labels, preds, average='macro', zero_division=0)
    return acc, f1, precision, recall

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

    acc, f1, prec, recall = compute_metrics(all_preds, all_labels)
    print(f"Eval | Acc: {acc:.4f} | F1: {f1:.4f} | Precision: {prec:.4f} | Recall: {recall:.4f}")
