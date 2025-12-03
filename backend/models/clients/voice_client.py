# backend/models/clients/voice_client.py
from __future__ import annotations

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import librosa
from typing import List, Any
from pathlib import Path

# ------------------------------
# 공통 설정
# ------------------------------
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

TARGET_SR    = 16000
N_MFCC       = 60
N_MELS       = 128
FRAME_LENGTH = 2048
HOP_LENGTH   = 512
FEATURE_DIM  = 202     # MFCC+Delta+Delta2+Prosody+ProsodyDelta

LABELS = ["기쁨", "분노", "불안", "슬픔"]  # 0~3 인덱스

# ------------------------------
# 모델 경로 (너희 백엔드 기준으로 수정)
# ------------------------------
BASE_DIR = Path(__file__).resolve().parents[2]   # backend/models/clients → parents[2] = project root
AUDIO_MODEL_PATH = BASE_DIR / "model_weights" / "audio_model.pt"


# =====================================================
# 1) CNN-BiLSTM 모델 클래스 (너가 보낸 구조 그대로)
# =====================================================
class CNNBiLSTM(nn.Module):
    def __init__(self, input_channels, num_classes, l2_reg=0.0, drop_rate=0.5):
        super().__init__()

        self.conv1 = nn.Conv1d(input_channels, 256, kernel_size=5, padding='same', bias=False)
        self.bn1   = nn.BatchNorm1d(256)
        self.relu  = nn.ReLU()
        self.pool1 = nn.MaxPool1d(kernel_size=2, stride=2, padding=1)
        self.dropout1 = nn.Dropout(drop_rate)

        self.conv2 = nn.Conv1d(256, 256, kernel_size=3, padding='same', bias=False)
        self.bn2   = nn.BatchNorm1d(256)
        self.pool2 = nn.MaxPool1d(kernel_size=2, stride=2, padding=1)
        self.dropout2 = nn.Dropout(drop_rate)

        self.lstm1 = nn.LSTM(
            input_size=256,
            hidden_size=128,
            batch_first=True,
            bidirectional=True
        )
        self.dropout3 = nn.Dropout(drop_rate)

        self.lstm2 = nn.LSTM(
            input_size=256,
            hidden_size=64,
            batch_first=True,
            bidirectional=True
        )
        self.dropout4 = nn.Dropout(drop_rate)

        self.dense1 = nn.Linear(128, 64)
        self.dropout5 = nn.Dropout(drop_rate)

        self.output_layer = nn.Linear(64, num_classes)

    def forward(self, x):  # x: [B, 202, T]
        x = self.relu(self.bn1(self.conv1(x)))
        x = self.pool1(x)
        x = self.dropout1(x)

        x = self.relu(self.bn2(self.conv2(x)))
        x = self.pool2(x)
        x = self.dropout2(x)

        x = x.permute(0, 2, 1)  # → [B, T, 256]

        x, _ = self.lstm1(x)
        x = self.dropout3(x)

        x, (h_n, _) = self.lstm2(x)

        forward_hidden  = h_n[-2, :, :]
        backward_hidden = h_n[-1, :, :]
        x = torch.cat((forward_hidden, backward_hidden), dim=1)

        x = self.relu(self.dense1(x))
        x = self.dropout5(x)

        logits = self.output_layer(x)
        return logits  # [B,4]


# =====================================================
# 2) 특징 추출 (MFCC + Delta + Prosody)
# =====================================================
def extract_mfcc_with_prosody(audio_path: str) -> np.ndarray:
    y, sr = librosa.load(audio_path, sr=TARGET_SR)

    mfcc = librosa.feature.mfcc(y=y, sr=sr,
                                n_mfcc=N_MFCC,
                                n_fft=FRAME_LENGTH,
                                hop_length=HOP_LENGTH,
                                n_mels=N_MELS)
    mfcc_delta  = librosa.feature.delta(mfcc)
    mfcc_delta2 = librosa.feature.delta(mfcc, order=2)

    zcr      = librosa.feature.zero_crossing_rate(y, frame_length=FRAME_LENGTH, hop_length=HOP_LENGTH)
    rmse     = librosa.feature.rms(y=y, frame_length=FRAME_LENGTH, hop_length=HOP_LENGTH)
    cent     = librosa.feature.spectral_centroid(y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH)
    bw       = librosa.feature.spectral_bandwidth(y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH)
    contrast = librosa.feature.spectral_contrast(y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH)

    prosody_base  = np.vstack([zcr, rmse, cent, bw, contrast])
    prosody_delta = librosa.feature.delta(prosody_base)

    combined = np.vstack([
        mfcc,
        mfcc_delta,
        mfcc_delta2,
        prosody_base,
        prosody_delta
    ])  # shape: (202, T)

    combined = (combined - np.mean(combined)) / np.std(combined)

    return combined.T  # (T, 202)


# =====================================================
# 3) 전처리 함수 (wav → [1,202,T] 텐서)
# =====================================================
def preprocess_audio(audio_path: str) -> torch.Tensor:
    features = extract_mfcc_with_prosody(audio_path)  # (T,202)
    features = features.astype(np.float32).T          # (202,T)
    tensor = torch.from_numpy(features).unsqueeze(0)  # [1,202,T]
    return tensor.to(DEVICE)


# =====================================================
# 4) 모델 로드
# =====================================================
_audio_model = None

def load_audio_model() -> CNNBiLSTM:
    global _audio_model
    if _audio_model is not None:
        return _audio_model

    model = CNNBiLSTM(input_channels=FEATURE_DIM,
                      num_classes=4,
                      drop_rate=0.5)

    state = torch.load(AUDIO_MODEL_PATH, map_location=DEVICE)
    model.load_state_dict(state)

    model.to(DEVICE)
    model.eval()
    _audio_model = model
    return model


# =====================================================
# 5) 앙상블용 확률 반환 함수 (핵심)
# =====================================================
def predict_voice_probs(audio_input: Any) -> List[float]:
    """
    앙상블 모델에서 호출할 최종 API.
    input: 음성 파일 경로 (string)
    output: 감정 확률 list[4] → [기쁨, 분노, 불안, 슬픔]
    """

    model = load_audio_model()

    audio_tensor = preprocess_audio(audio_input)  # [1,202,T]

    with torch.no_grad():
        logits = model(audio_tensor)   # [1,4]
        probs = F.softmax(logits, dim=1)[0].cpu().numpy().tolist()

    return probs  # ★ 앙상블에서 요구하는 최종 출력
