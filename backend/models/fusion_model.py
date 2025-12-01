# backend/models/fusion_model.py

import os
from typing import Tuple, List

import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import librosa

from torchvision.models import efficientnet_b0, EfficientNet_B0_Weights
from transformers import BertModel
from kobert_transformers import get_tokenizer

from config import IMAGE_PT_PATH, TEXT_PT_PATH, AUDIO_PT_PATH, FUSION_PT_PATH

# ---------------------------
# 공통 설정
# ---------------------------
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
MAX_TIMESTEPS = 286

DIM_IMAGE = 7
DIM_TEXT  = 6
DIM_AUDIO = 7
FUSION_INPUT_DIM = DIM_IMAGE + DIM_TEXT + DIM_AUDIO
NUM_CLASSES = 10

GLOBAL_EMOTION_ID_TO_NAME = {
    0: "기쁨",
    1: "당황",
    2: "분노",
    3: "불안",
    4: "상처",
    5: "슬픔",
    6: "중립",
    7: "역겨움",
    8: "공포",
    9: "놀람",
}

# ---------------------------
# 텍스트 인코딩 (KoBERT)
# ---------------------------
tokenizer = get_tokenizer()
MAX_TEXT_LEN = 192

def encode_text_batch(text_list, device=DEVICE):
    enc = tokenizer(
        text_list,
        return_tensors="pt",
        padding=True,
        truncation=True,
        max_length=MAX_TEXT_LEN,
    )
    input_ids = enc["input_ids"]
    token_type_ids = enc["token_type_ids"]
    attention_mask = enc["attention_mask"]
    valid_length = attention_mask.sum(dim=1)

    return (
        input_ids.to(device),
        valid_length.to(device),
        token_type_ids.to(device),
    )

# ---------------------------
# 오디오 전처리
# ---------------------------
def extract_mfcc_prosody_202(audio_path, sr=16000, n_mfcc=40):
    y, sr = librosa.load(audio_path, sr=sr)
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=n_mfcc).T
    delta = librosa.feature.delta(mfcc, order=1)
    delta2 = librosa.feature.delta(mfcc, order=2)
    feats = np.concatenate([mfcc, delta, delta2], axis=1)  # (T, 120)

    T, F = feats.shape
    if F < 180:
        pad = np.zeros((T, 180 - F), dtype=feats.dtype)
        feats = np.concatenate([feats, pad], axis=1)
    elif F > 180:
        feats = feats[:, :180]

    return feats

def wav_to_tensor_180(audio_path, device=DEVICE):
    feats = extract_mfcc_prosody_202(audio_path)
    T, F = feats.shape

    if T < MAX_TIMESTEPS:
        pad_len = MAX_TIMESTEPS - T
        feats = np.pad(feats, ((0, pad_len), (0, 0)), mode="constant")
    else:
        feats = feats[:MAX_TIMESTEPS, :]

    feats = feats.T  # (180, 286)
    tensor = torch.from_numpy(feats).float().unsqueeze(0).to(device)
    return tensor

# ---------------------------
# 서브모델 정의
# ---------------------------
class BERTClassifier(nn.Module):
    def __init__(self, bert, hidden_size=768, num_classes=6, dr_rate=0.3):
        super().__init__()
        self.bert = bert
        self.dropout = nn.Dropout(dr_rate)
        self.classifier = nn.Linear(hidden_size, num_classes)

    def gen_attention_mask(self, token_ids, valid_length):
        attn_mask = torch.zeros_like(token_ids)
        for i, v in enumerate(valid_length):
            attn_mask[i][:v] = 1
        return attn_mask.float()

    def forward(self, token_ids, valid_length, segment_ids):
        attention_mask = self.gen_attention_mask(token_ids, valid_length)
        _, pooled = self.bert(
            input_ids=token_ids,
            token_type_ids=segment_ids,
            attention_mask=attention_mask.to(token_ids.device),
            return_dict=False,
        )
        pooled = self.dropout(pooled)
        return self.classifier(pooled)

class CNNBiLSTM(nn.Module):
    def __init__(self, input_channels, num_classes, drop_rate=0.5):
        super().__init__()
        self.conv1 = nn.Conv1d(input_channels, 256, kernel_size=5, padding='same', bias=False)
        self.bn1 = nn.BatchNorm1d(256)
        self.relu = nn.ReLU()
        self.pool1 = nn.MaxPool1d(kernel_size=2, stride=2, padding=1)
        self.dropout1 = nn.Dropout(drop_rate)

        self.conv2 = nn.Conv1d(256, 256, kernel_size=3, padding='same', bias=False)
        self.bn2 = nn.BatchNorm1d(256)
        self.pool2 = nn.MaxPool1d(kernel_size=2, stride=2, padding=1)
        self.dropout2 = nn.Dropout(drop_rate)

        with torch.no_grad():
            dummy = torch.zeros(1, input_channels, MAX_TIMESTEPS)
            x = self.pool1(self.relu(self.bn1(self.conv1(dummy))))
            x = self.pool2(self.relu(self.bn2(self.conv2(x))))
            lstm_input_size = x.size(1)
            lstm_seq_len = x.size(2)
        print(f"[Audio] LSTM size={lstm_input_size}, seq_len={lstm_seq_len}")

        self.lstm1 = nn.LSTM(lstm_input_size, 128, batch_first=True, bidirectional=True)
        self.dropout3 = nn.Dropout(drop_rate)
        self.lstm2 = nn.LSTM(128 * 2, 64, batch_first=True, bidirectional=True)
        self.dropout4 = nn.Dropout(drop_rate)

        self.dense1 = nn.Linear(64 * 2, 64)
        self.dropout5 = nn.Dropout(drop_rate)
        self.output_layer = nn.Linear(64, num_classes)

    def forward(self, x):
        x = self.conv1(x); x = self.bn1(x); x = self.relu(x); x = self.pool1(x); x = self.dropout1(x)
        x = self.conv2(x); x = self.bn2(x); x = self.relu(x); x = self.pool2(x); x = self.dropout2(x)
        x = x.permute(0, 2, 1)
        x, _ = self.lstm1(x); x = self.dropout3(x)
        x, (h_n, _) = self.lstm2(x)
        forward_h = h_n[-2, :, :]
        backward_h = h_n[-1, :, :]
        x = torch.cat((forward_h, backward_h), dim=1)
        x = self.relu(self.dense1(x))
        x = self.dropout5(x)
        x = self.output_layer(x)
        return x

class FusionHead(nn.Module):
    def __init__(self, input_dim=FUSION_INPUT_DIM, num_classes=NUM_CLASSES):
        super().__init__()
        self.fc1 = nn.Linear(input_dim, 64)
        self.bn1 = nn.BatchNorm1d(64)
        self.fc2 = nn.Linear(64, num_classes)

    def forward(self, x):
        x = self.fc1(x)
        x = self.bn1(x)
        x = F.relu(x)
        x = self.fc2(x)
        return x

# ---------------------------
# 멀티모달 EmotionAnalyzer
# ---------------------------
class EmotionAnalyzer:
    def __init__(self):
        # 이미지
        image_model = efficientnet_b0(weights=EfficientNet_B0_Weights.DEFAULT)
        num_features = image_model.classifier[1].in_features
        image_model.classifier[1] = nn.Linear(num_features, DIM_IMAGE)
        image_model.load_state_dict(torch.load(IMAGE_PT_PATH, map_location=DEVICE))
        image_model.to(DEVICE).eval()

        # 텍스트
        bert = BertModel.from_pretrained("skt/kobert-base-v1")
        text_model = BERTClassifier(bert, num_classes=DIM_TEXT)
        text_model.load_state_dict(torch.load(TEXT_PT_PATH, map_location=DEVICE))
        text_model.to(DEVICE).eval()

        # 오디오
        audio_model = CNNBiLSTM(180, DIM_AUDIO)
        audio_model.load_state_dict(torch.load(AUDIO_PT_PATH, map_location=DEVICE))
        audio_model.to(DEVICE).eval()

        # Fusion
        fusion_head = FusionHead()
        fusion_head.load_state_dict(torch.load(FUSION_PT_PATH, map_location=DEVICE))
        fusion_head.to(DEVICE).eval()

        self.image_model = image_model
        self.text_model = text_model
        self.audio_model = audio_model
        self.fusion_head = fusion_head

    @torch.no_grad()
    def predict(
        self,
        image_tensor: torch.Tensor,  # [1,3,224,224]
        text_str: str,
        audio_path: str,
    ) -> Tuple[int, str, List[float]]:
        logits_img = self.image_model(image_tensor.to(DEVICE))  # [1,7]

        input_ids, valid_len, seg_ids = encode_text_batch([text_str], device=DEVICE)
        logits_text = self.text_model(input_ids, valid_len, seg_ids)  # [1,6]

        audio_tensor = wav_to_tensor_180(audio_path, device=DEVICE)
        logits_audio = self.audio_model(audio_tensor)  # [1,7]

        fusion_in = torch.cat([logits_img, logits_text, logits_audio], dim=1)  # [1,20]
        logits = self.fusion_head(fusion_in)  # [1,10]
        prob = torch.softmax(logits, dim=1)
        pred_id = int(prob.argmax(dim=1).item())
        pred_name = GLOBAL_EMOTION_ID_TO_NAME.get(pred_id, "Unknown")
        return pred_id, pred_name, prob.cpu().numpy().tolist()[0]


# 싱글톤처럼 한 번 로딩해서 계속 사용
_emotion_analyzer: EmotionAnalyzer | None = None

def get_emotion_analyzer() -> EmotionAnalyzer:
    global _emotion_analyzer
    if _emotion_analyzer is None:
        _emotion_analyzer = EmotionAnalyzer()

    return _emotion_analyzer
