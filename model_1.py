import torch
from torch.utils.data import Dataset, DataLoader
from transformers import BertTokenizer, BertForSequenceClassification, AdamW
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
import pandas as pd
from tqdm import tqdm

data_path = r"C:\Users\jiheo\OneDrive\Desktop\emotion_dataset.csv"
df = pd.read_csv(data_path)

train_texts, test_texts, train_labels, test_labels = train_test_split(
    df['text'].tolist(),
    df['label_num'].tolist(),
    test_size=0.2,
    random_state=42,
    stratify=df['label_num']
)

tokenizer = BertTokenizer.from_pretrained('monologg/kobert')
max_len = 64
train_encodings = tokenizer(train_texts, truncation=True, padding=True, max_length=max_len)
test_encodings = tokenizer(test_texts, truncation=True, padding=True, max_length=max_len)

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
model = BertForSequenceClassification.from_pretrained('monologg/kobert', num_labels=6)
model.to(device)
optimizer = AdamW(model.parameters(), lr=2e-5)

def compute_metrics(preds, labels):
    acc = accuracy_score(labels, preds)
    f1 = f1_score(labels, preds, average='macro')
    precision = precision_score(labels, preds, average='macro')
    recall = recall_score(labels, preds, average='macro')
    return acc, f1, precision, recall

epochs = 3
for epoch in range(epochs):
    print(f"\n===== Epoch {epoch+1}/{epochs} =====")

    model.train()
    train_loss = 0
    train_loop = tqdm(train_loader, desc=f"Training", leave=False)

    for batch in train_loop:
        optimizer.zero_grad()
        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['labels'].to(device)

        outputs = model(input_ids, attention_mask=attention_mask, labels=labels)
        loss = outputs.loss
        loss.backward()
        optimizer.step()

        train_loss += loss.item()
        train_loop.set_postfix(loss=f"{loss.item():.4f}")

    avg_train_loss = train_loss / len(train_loader)
    print(f"Training Loss: {avg_train_loss:.4f}")

    model.eval()
    all_preds, all_labels = [], []
    eval_loop = tqdm(test_loader, desc=f"🔍 Evaluating", leave=False)

    with torch.no_grad():
        for batch in eval_loop:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['labels'].to(device)

            outputs = model(input_ids, attention_mask=attention_mask)
            preds = outputs.logits.argmax(dim=1)
            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    acc, f1, precision, recall = compute_metrics(all_preds, all_labels)
    print(f" Eval | Acc: {acc:.4f} | F1: {f1:.4f} | Prec: {precision:.4f} | Recall: {recall:.4f}")
