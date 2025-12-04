# backend/models/clients/text_client.py

"""
텍스트 감정 분석 클라이언트 (KoBERT 4클래스용)

역할:
- KoBERT 토크나이저 & 모델 로드
- 전처리(BERTSentenceTransform)
- 문장 입력 → [기쁨, 분노, 불안, 슬픔] 확률 반환
"""

from __future__ import annotations
from typing import List, Tuple

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from pathlib import Path

from kobert_tokenizer import KoBERTTokenizer
from transformers import BertModel


# ========================
# 0. 기본 설정
# ========================

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 🔥 상대 경로로 모델 weight 로드 (절대경로 절대 금지!!!)
BASE_DIR = Path(__file__).resolve().parent.parent  # backend/models
WEIGHT_DIR = BASE_DIR / "weights"
TEXT_MODEL_PATH = WEIGHT_DIR / "text_model.pt"

MAX_SEQ_LEN = 64
EMOTION_LABELS = ["기쁨", "분노", "불안", "슬픔"]


# ========================
# 1. 전처리 클래스
# ========================

class BERTSentenceTransform:
    def __init__(self, tokenizer, max_seq_length, pad=True, pair=False):
        self._tokenizer = tokenizer
        self._max_seq_length = max_seq_length
        self._pad = pad
        self._pair = pair

    def _truncate_seq_pair(self, tokens_a, tokens_b, max_length):
        while True:
            total_length = len(tokens_a) + len(tokens_b)
            if total_length <= max_length:
                break
            if len(tokens_a) > len(tokens_b):
                tokens_a.pop()
            else:
                tokens_b.pop()

    def __call__(self, line):
        text_a = line[0]
        tokens_a = self._tokenizer.tokenize(text_a)

        tokens_b = None
        if self._pair:
            assert len(line) == 2
            text_b = line[1]
            tokens_b = self._tokenizer.tokenize(text_b)

        if tokens_b:
            self._truncate_seq_pair(tokens_a, tokens_b, self._max_seq_length - 3)
        else:
            tokens_a = tokens_a[: self._max_seq_length - 2]

        tokens = [self._tokenizer.cls_token] + tokens_a + [self._tokenizer.sep_token]
        segment_ids = [0] * len(tokens)

        if tokens_b:
            tokens += tokens_b + [self._tokenizer.sep_token]
            segment_ids += [1] * (len(tokens) - len(segment_ids))

        input_ids = self._tokenizer.convert_tokens_to_ids(tokens)
        valid_length = len(input_ids)

        if self._pad:
            pad_len = self._max_seq_length - valid_length
            input_ids += [self._tokenizer.pad_token_id] * pad_len
            segment_ids += [0] * pad_len

        return (
            np.array(input_ids, dtype="int32"),
            np.array(valid_length, dtype="int32"),
            np.array(segment_ids, dtype="int32"),
        )


# ========================
# 2. KoBERT 분류 모델
# ========================

class BERTClassifier(nn.Module):
    def __init__(self, bert, num_classes=4, dr_rate=0.5):
        super().__init__()
        self.bert = bert
        self.dr_rate = dr_rate
        self.dropout = nn.Dropout(p=dr_rate)
        self.classifier = nn.Linear(bert.config.hidden_size, num_classes)

    def gen_attention_mask(self, token_ids, valid_length):
        attention_mask = torch.zeros_like(token_ids)
        for i, v in enumerate(valid_length):
            attention_mask[i, :v] = 1
        return attention_mask

    def forward(self, token_ids, valid_length, segment_ids):
        attention_mask = self.gen_attention_mask(token_ids, valid_length).to(token_ids.device)

        _, pooler = self.bert(
            input_ids=token_ids,
            token_type_ids=segment_ids.long(),
            attention_mask=attention_mask.float(),
            return_dict=False,
        )

        if self.dropout:
            pooler = self.dropout(pooler)

        return self.classifier(pooler)


# ========================
# 3. 전역 싱글톤
# ========================

_tokenizer = None
_transform = None
_text_model = None
_initialized = False


def _init_text_model():
    global _tokenizer, _transform, _text_model, _initialized

    if _initialized:
        return

    # 1) Tokenizer & BERT backbone
    _tokenizer = KoBERTTokenizer.from_pretrained("skt/kobert-base-v1")
    bert_model = BertModel.from_pretrained("skt/kobert-base-v1", return_dict=False)

    # 2) Classifier wrapper
    _text_model = BERTClassifier(bert=bert_model, num_classes=4, dr_rate=0.6).to(DEVICE)

    # 3) Load trained weights
    if not TEXT_MODEL_PATH.exists():
        raise FileNotFoundError(f"텍스트 모델 weight 파일이 없습니다: {TEXT_MODEL_PATH}")

    state = torch.load(TEXT_MODEL_PATH, map_location=DEVICE)
    _text_model.load_state_dict(state)
    _text_model.eval()

    # 4) Preprocessing transform
    _transform = BERTSentenceTransform(_tokenizer, MAX_SEQ_LEN, pad=True)

    _initialized = True
    print(f"[TEXT_CLIENT] 텍스트 모델 로드 완료 → {TEXT_MODEL_PATH}")


# ========================
# 4. 외부 API
# ========================

def predict_text_probs(text: str) -> List[float]:
    """입력 문장을 4개 감정 확률로 반환"""
    if not text:
        return [0.25, 0.25, 0.25, 0.25]

    if not _initialized:
        _init_text_model()

    ids_np, valid_np, seg_np = _transform([text])

    token_ids = torch.tensor([ids_np]).to(DEVICE)
    valid_length = torch.tensor([valid_np]).to(DEVICE)
    segment_ids = torch.tensor([seg_np]).to(DEVICE)

    with torch.no_grad():
        logits = _text_model(token_ids, valid_length, segment_ids)
        probs = F.softmax(logits, dim=-1)[0].cpu().numpy()

    return [float(p) for p in probs]
