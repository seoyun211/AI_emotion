# backend/models/clients/voice_client.py

from __future__ import annotations
from typing import List, Optional

from pathlib import Path
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import librosa


DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

BASE_DIR = Path(__file__).resolve().parent.parent
WEIGHT_DIR = BASE_DIR / "weights"
AUDIO_MODEL_PATH = WEIGHT_DIR / "audio_model.pt"  # ← 네가 저장한 이름으로 맞춰줘

EMOTION_LABELS = ["기쁨", "분노", "불안", "슬픔"]


# === 오디오 특징 설정 (네 이전 코드 기준) ===
TARGET_SR = 16000
N_MFCC = 60
N_MELS = 128
FRAME_LENGTH = 2048
HOP_LENGTH = 512
FEATURE_DIM = 202  # MFCC+delta+delta2 + prosody + prosody_delta


def extract_mfcc_with_prosody(audio_path: str) -> Optional[np.ndarray]:
    try:
        y, sr = librosa.load(audio_path, sr=TARGET_SR)

        mfcc = librosa.feature.mfcc(
            y=y,
            sr=sr,
            n_mfcc=N_MFCC,
            n_fft=FRAME_LENGTH,
            hop_length=HOP_LENGTH,
            n_mels=N_MELS,
        )
        mfcc_delta = librosa.feature.delta(mfcc)
        mfcc_delta2 = librosa.feature.delta(mfcc, order=2)

        zcr = librosa.feature.zero_crossing_rate(
            y=y, frame_length=FRAME_LENGTH, hop_length=HOP_LENGTH
        )
        rmse = librosa.feature.rms(
            y=y, frame_length=FRAME_LENGTH, hop_length=HOP_LENGTH
        )
        cent = librosa.feature.spectral_centroid(
            y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH
        )
        bw = librosa.feature.spectral_bandwidth(
            y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH
        )
        contrast = librosa.feature.spectral_contrast(
            y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH
        )

        prosody_base = np.vstack([zcr, rmse, cent, bw, contrast])
        prosody_delta = librosa.feature.delta(prosody_base)

        combined = np.vstack(
            [mfcc, mfcc_delta, mfcc_delta2, prosody_base, prosody_delta]
        )  # [202, T]

        combined = (combined - np.mean(combined)) / np.std(combined)
        return combined.T  # [T, 202]

    except Exception as e:
        print(f"[VOICE_CLIENT] 특징 추출 실패: {audio_path} ({e})")
        return None


def preprocess_audio(audio_path: str, max_timesteps: int = None) -> torch.Tensor:
    feats = extract_mfcc_with_prosody(audio_path)
    if feats is None:
        raise RuntimeError(f"오디오 특징 추출 실패: {audio_path}")

    if max_timesteps is not None:
        T = feats.shape[0]
        if T < max_timesteps:
            pad = np.zeros((max_timesteps - T, FEATURE_DIM), dtype=np.float32)
            feats = np.vstack([feats, pad])
        elif T > max_timesteps:
            feats = feats[:max_timesteps, :]

    feats = feats.astype(np.float32).T  # [202, T]
    tensor = torch.from_numpy(feats).unsqueeze(0).to(DEVICE)  # [1,202,T]
    return tensor


class CNNBiLSTM(nn.Module):
    """
    audio_model.pt 의 state_dict 키:
      - "... output_layer.weight", "output_layer.bias"
    에 맞추기 위해 self.output_layer 사용
    """
    def __init__(self, input_channels: int, num_classes: int, drop_rate: float = 0.5):
        super().__init__()
        self.conv1 = nn.Conv1d(input_channels, 256, kernel_size=5, padding="same", bias=False)
        self.bn1 = nn.BatchNorm1d(256)
        self.pool1 = nn.MaxPool1d(kernel_size=2, stride=2, padding=1)
        self.dropout1 = nn.Dropout(drop_rate)

        self.conv2 = nn.Conv1d(256, 256, kernel_size=3, padding="same", bias=False)
        self.bn2 = nn.BatchNorm1d(256)
        self.pool2 = nn.MaxPool1d(kernel_size=2, stride=2, padding=1)
        self.dropout2 = nn.Dropout(drop_rate)

        self.lstm1 = nn.LSTM(
            input_size=256,
            hidden_size=128,
            batch_first=True,
            bidirectional=True,
        )
        self.dropout3 = nn.Dropout(drop_rate)

        self.lstm2 = nn.LSTM(
            input_size=256,
            hidden_size=64,
            batch_first=True,
            bidirectional=True,
        )
        self.dropout4 = nn.Dropout(drop_rate)

        self.dense1 = nn.Linear(128, 64)
        self.dropout5 = nn.Dropout(drop_rate)

        # 🔹 학습 때 쓰인 이름에 맞춰서
        self.output_layer = nn.Linear(64, num_classes)

    def forward(self, x):
        # x: [B, C, T]
        x = self.conv1(x)
        x = self.bn1(x)
        x = torch.relu(x)
        x = self.pool1(x)
        x = self.dropout1(x)

        x = self.conv2(x)
        x = self.bn2(x)
        x = torch.relu(x)
        x = self.pool2(x)
        x = self.dropout2(x)

        x = x.permute(0, 2, 1)  # [B,T,C]

        x, _ = self.lstm1(x)
        x = self.dropout3(x)

        x, (h_n, _) = self.lstm2(x)
        fwd = h_n[-2, :, :]
        bwd = h_n[-1, :, :]
        x = torch.cat((fwd, bwd), dim=1)  # [B,128]

        x = torch.relu(self.dense1(x))
        x = self.dropout5(x)
        return self.output_layer(x)


_audio_model: Optional[CNNBiLSTM] = None


def _init_audio_model():
    global _audio_model
    if _audio_model is not None:
        return
    if not AUDIO_MODEL_PATH.exists():
        raise FileNotFoundError(f"음성 모델 weight 파일이 없습니다: {AUDIO_MODEL_PATH}")
    model = CNNBiLSTM(input_channels=FEATURE_DIM, num_classes=len(EMOTION_LABELS)).to(DEVICE)
    state = torch.load(AUDIO_MODEL_PATH, map_location=DEVICE)
    model.load_state_dict(state)   # 이제 키 이름이 맞음
    model.eval()
    _audio_model = model
    print(f"[VOICE_CLIENT] 음성 모델 로드 완료 → {AUDIO_MODEL_PATH}")


def predict_voice_probs(wav_path: str) -> List[float]:
    """
    wav 파일 경로 입력 → [기쁨, 분노, 불안, 슬픔] 확률 반환
    """
    _init_audio_model()
    tensor = preprocess_audio(wav_path, max_timesteps=None)  # [1,202,T]
    with torch.no_grad():
        logits = _audio_model(tensor)  # [1,4]
        probs = F.softmax(logits, dim=1)[0].cpu().numpy()

    print(f"[VOICE_CLIENT] wav_path: {wav_path}")
    print(f"[VOICE_CLIENT] 확률: {probs}")

    return [float(p) for p in probs]
