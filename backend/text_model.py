import pandas as pd
import torch
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
from transformers import (
    BertForSequenceClassification, Trainer, TrainingArguments,
    DataCollatorWithPadding, TrainerCallback
)
from datasets import Dataset, DatasetDict
from kobert_transformers import get_tokenizer

# ============================================
# 1️⃣ 데이터 불러오기
# ============================================
csv_path = r"C:\Users\jiheo\OneDrive\Desktop\emotion_dataset.csv"
df = pd.read_csv(csv_path)
print(f"✅ 데이터 로드 완료: {df.shape}")

# ============================================
# 2️⃣ 학습/검증 데이터 분리
# ============================================
train_df, val_df = train_test_split(df, test_size=0.2, stratify=df['label_num'], random_state=42)

# ============================================
# 3️⃣ Dataset 변환
# ============================================
train_dataset = Dataset.from_pandas(train_df)
val_dataset = Dataset.from_pandas(val_df)
dataset = DatasetDict({"train": train_dataset, "validation": val_dataset})

# ============================================
# 4️⃣ KoBERT 토크나이저
# ============================================
tokenizer = get_tokenizer()

def tokenize_function(examples):
    return tokenizer(examples['text'], truncation=True, padding='max_length', max_length=128)

tokenized_datasets = dataset.map(tokenize_function, batched=True)

# ============================================
# 5️⃣ KoBERT 모델 (6개 감정 분류)
# ============================================
model = BertForSequenceClassification.from_pretrained("monologg/kobert", num_labels=6)

# ============================================
# 6️⃣ 데이터 컬레이터
# ============================================
data_collator = DataCollatorWithPadding(tokenizer=tokenizer)

# ============================================
# 7️⃣ 평가 지표 함수
# ============================================
def compute_metrics(eval_pred):
    logits, labels = eval_pred
    preds = logits.argmax(axis=-1)
    return {
        "accuracy": accuracy_score(labels, preds),
        "f1": f1_score(labels, preds, average="macro"),
        "precision": precision_score(labels, preds, average="macro"),
        "recall": recall_score(labels, preds, average="macro"),
    }

# ============================================
# 8️⃣ 학습 진행률 콜백
# ============================================
class ProgressCallback(TrainerCallback):
    def on_log(self, args, state, control, logs=None, **kwargs):
        if logs:
            print(f"Step {state.global_step}, Epoch {state.epoch:.2f}, Logs: {logs}")

# ============================================
# 9️⃣ TrainingArguments 설정
# ============================================
training_args = TrainingArguments(
    output_dir="./kobert_emotion_model",
    num_train_epochs=4,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=32,
    learning_rate=2e-5,
    weight_decay=0.01,
    evaluation_strategy="steps",
    eval_steps=100,
    logging_steps=10,
    save_steps=200,
    load_best_model_at_end=True,
    metric_for_best_model="f1",
    logging_dir="./logs",
    report_to=[]  # wandb 비활성화
)

# ============================================
# 🔟 Trainer 초기화
# ============================================
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_datasets["train"],
    eval_dataset=tokenized_datasets["validation"],
    tokenizer=tokenizer,
    data_collator=data_collator,
    compute_metrics=compute_metrics,
    callbacks=[ProgressCallback()]
)

# ============================================
# 1️⃣1️⃣ 모델 학습 시작
# ============================================
print("🚀 학습 시작...")
trainer.train()
print("✅ 학습 완료!")

# ============================================
# 1️⃣2️⃣ 모델 저장
# ============================================
trainer.save_model("./kobert_emotion_model_final")
print("💾 모델 저장 완료: ./kobert_emotion_model_final")

# ============================================
# 1️⃣3️⃣ 검증 데이터 평가
# ============================================
predictions_output = trainer.predict(tokenized_datasets["validation"])
logits = predictions_output.predictions
labels = predictions_output.label_ids
preds = logits.argmax(axis=-1)

accuracy = accuracy_score(labels, preds)
f1 = f1_score(labels, preds, average="macro")
precision = precision_score(labels, preds, average="macro")
recall = recall_score(labels, preds, average="macro")

print("\n📊 검증 데이터셋 성능:")
print(f"Accuracy : {accuracy:.4f}")
print(f"F1 Score : {f1:.4f}")
print(f"Precision: {precision:.4f}")
print(f"Recall   : {recall:.4f}")
