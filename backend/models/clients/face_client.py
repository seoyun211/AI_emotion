# backend/models/clients/face_client.py

from __future__ import annotations
from typing import List, Optional

from pathlib import Path
import io

import numpy as np
import cv2
from PIL import Image

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision.models import efficientnet_b0
import torchvision.transforms as transforms

import mediapipe as mp


DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 상대경로: backend/models/weights/image_model.pt
BASE_DIR = Path(__file__).resolve().parent.parent
WEIGHT_DIR = BASE_DIR / "weights"
IMAGE_MODEL_PATH = WEIGHT_DIR / "image_model.pt"

EMOTION_LABELS = ["기쁨", "분노", "불안", "슬픔"]


def get_image_transform():
    return transforms.Compose(
        [
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
        ]
    )


class ExpressionNet(nn.Module):
    def __init__(self, num_classes: int = 4):
        super().__init__()
        model = efficientnet_b0(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(in_features, num_classes)
        self.backbone = model

    def forward(self, x):
        return self.backbone(x)


_face_model: Optional[ExpressionNet] = None
_face_transform = get_image_transform()
_mp_face = mp.solutions.face_detection.FaceDetection(
    model_selection=1, min_detection_confidence=0.5
)


def _init_face_model():
    global _face_model
    if _face_model is not None:
        return
    if not IMAGE_MODEL_PATH.exists():
        raise FileNotFoundError(f"이미지 모델 weight 파일이 없습니다: {IMAGE_MODEL_PATH}")
    model = ExpressionNet(num_classes=len(EMOTION_LABELS)).to(DEVICE)
    state = torch.load(IMAGE_MODEL_PATH, map_location=DEVICE)
    model.load_state_dict(state)
    model.eval()
    _face_model = model
    print(f"[FACE_CLIENT] 이미지 모델 로드 완료 → {IMAGE_MODEL_PATH}")


def _detect_face_bbox(rgb_frame: np.ndarray, scale: float = 0.5):
    h, w, _ = rgb_frame.shape
    small_rgb = cv2.resize(rgb_frame, (0, 0), fx=scale, fy=scale)
    results = _mp_face.process(small_rgb)
    if not results.detections:
        return None
    det = results.detections[0]
    bbox = det.location_data.relative_bounding_box

    x1 = int(bbox.xmin * w)
    y1 = int(bbox.ymin * h)
    x2 = int((bbox.xmin + bbox.width) * w)
    y2 = int((bbox.ymin + bbox.height) * h)

    x1, y1 = max(0, x1), max(0, y1)
    x2, y2 = min(w, x2), min(h, y2)
    if x2 <= x1 or y2 <= y1:
        return None
    return (x1, y1, x2, y2)


def _frame_bytes_to_face_tensor(frame_bytes: bytes):
    """
    1개 프레임(bytes) → 얼굴 crop → [1,3,224,224] tensor (or None)
    """
    # bytes → np array → BGR image
    np_arr = np.frombuffer(frame_bytes, np.uint8)
    bgr = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    if bgr is None:
        return None

    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    bbox = _detect_face_bbox(rgb, scale=0.5)
    if bbox is None:
        return None

    x1, y1, x2, y2 = bbox
    face = rgb[y1:y2, x1:x2]
    if face.size == 0:
        return None

    pil_img = Image.fromarray(face)
    tensor = _face_transform(pil_img).unsqueeze(0).to(DEVICE)  # [1,3,224,224]
    return tensor


def _infer_probs_for_tensor(img_tensor: torch.Tensor) -> List[float]:
    _init_face_model()
    with torch.no_grad():
        logits = _face_model(img_tensor)
        probs = F.softmax(logits, dim=1)[0].cpu().numpy()
    return [float(p) for p in probs]


def predict_face_probs_from_frames(frame_bytes_list: Optional[List[bytes]]) -> List[float]:
    """
    여러 프레임(bytes 리스트)을 받아, 유효한 얼굴 프레임들에 대해
    각각 예측 → 평균 확률을 반환.
    """
    if not frame_bytes_list:
        return [0.25, 0.25, 0.25, 0.25]

    all_probs = []
    for fb in frame_bytes_list:
        tensor = _frame_bytes_to_face_tensor(fb)
        if tensor is None:
            continue
        probs = _infer_probs_for_tensor(tensor)
        all_probs.append(probs)

    if not all_probs:
        return [0.25, 0.25, 0.25, 0.25]

    arr = np.array(all_probs)  # [N,4]
    mean_probs = arr.mean(axis=0)
    s = float(mean_probs.sum())
    if s > 0:
        mean_probs = mean_probs / s
    return [float(p) for p in mean_probs]
