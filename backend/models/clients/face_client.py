# backend/models/clients/face_client.py

from __future__ import annotations
from typing import List, Optional

from pathlib import Path
import numpy as np
import cv2
from PIL import Image

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision.models import efficientnet_b0
import torchvision.transforms as transforms

from ultralytics import YOLO  # 🔥 YOLOv8 (자동으로 yolov8n.pt 다운로드)


# ====================================================
# 0. 공통 설정 (경로 / 디바이스 / 라벨)
# ====================================================

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 상대경로: backend/models/weights/image_model.pt
BASE_DIR = Path(__file__).resolve().parent.parent   # backend/models
WEIGHT_DIR = BASE_DIR / "weights"

# 🔹 여기만 네가 실제로 저장한 이미지 모델 파일명에 맞춰 두면 됨
IMAGE_MODEL_PATH = WEIGHT_DIR / "image_model.pt"    # 4클래스 표정 모델 (.pt)

EMOTION_LABELS = ["기쁨", "분노", "불안", "슬픔"]  # 0,1,2,3


# ====================================================
# 1. 이미지 감정 모델 (EfficientNet-B0)
#   - state_dict 키: "features.*", "classifier.*" 에 맞춤
# ====================================================

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
    """
    torchvision EfficientNet-B0 구조에 맞춘 래퍼
    - classifier는 보통 Sequential(Dropout, Linear)
    - state_dict 키는 "features.*", "classifier.*" 형태
    """
    def __init__(self, num_classes: int = 4):
        super().__init__()
        base = efficientnet_b0(weights=None)

        # classifier: [Dropout, Linear]
        in_features = base.classifier[1].in_features
        base.classifier[1] = nn.Linear(in_features, num_classes)

        self.features = base.features
        self.avgpool = base.avgpool
        self.classifier = base.classifier  # ✅ dropout 포함된 전체 classifier를 그대로 사용

    def forward(self, x):
        x = self.features(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        x = self.classifier(x)  # ✅ dropout + linear 한번에 처리
        return x



_face_model: Optional[ExpressionNet] = None
_yolo_model: Optional[YOLO] = None

_face_transform = get_image_transform()


def _init_models():
    """
    YOLOv8n + 이미지 표정 모델을 한 번만 로드
    """
    global _face_model, _yolo_model

    # 1) 이미지 감정 모델 로드
    if _face_model is None:
        if not IMAGE_MODEL_PATH.exists():
            raise FileNotFoundError(f"이미지 모델 weight 파일이 없습니다: {IMAGE_MODEL_PATH}")
        model = ExpressionNet(num_classes=len(EMOTION_LABELS)).to(DEVICE)
        state = torch.load(IMAGE_MODEL_PATH, map_location=DEVICE)
        model.load_state_dict(state)  # strict=True 기본값, 이제 키가 맞음
        model.eval()
        _face_model = model
        print(f"[FACE_CLIENT] 이미지 모델 로드 완료 → {IMAGE_MODEL_PATH}")

    # 2) YOLOv8n 얼굴 검출 모델 로드 (자동 다운로드)
    if _yolo_model is None:
        # ⚠ 인터넷 연결이 되어 있어야 최초 1회 다운로드 가능
        _yolo_model = YOLO("yolov8n.pt")
        print("[FACE_CLIENT] YOLOv8n 모델 로드 완료 (yolov8n.pt 자동 다운로드)")


# ====================================================
# 2. YOLO로 얼굴 박스 검출 + crop
# ====================================================

def _get_face_crop_from_bytes(frame_bytes: bytes) -> Optional[Image.Image]:
    """
    1개 프레임(bytes) → YOLOv8n으로 박스 검출 → 가장 conf 높은 박스 crop
    """
    _init_models()
    assert _yolo_model is not None

    # bytes → np array → BGR
    np_arr = np.frombuffer(frame_bytes, np.uint8)
    bgr = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    if bgr is None:
        print("[YOLO] 이미지 디코딩 실패")
        return None

    # BGR → RGB
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)

    # YOLO 추론
    results = _yolo_model(rgb)[0]
    boxes = results.boxes

    n_boxes = 0 if boxes is None else len(boxes)
    print(f"[YOLO] 감지된 박스 수: {n_boxes}")

    if boxes is None or len(boxes) == 0:
        print("[YOLO] 얼굴 박스 없음 → 기본값 사용")
        return None

    # 가장 confidence 높은 박스 1개 선택
    xyxy = boxes.xyxy.cpu().numpy()   # (N, 4)
    conf = boxes.conf.cpu().numpy()   # (N,)

    best_idx = int(np.argmax(conf))
    x1, y1, x2, y2 = xyxy[best_idx]

    h, w, _ = rgb.shape
    x1 = int(max(0, min(w - 1, x1)))
    y1 = int(max(0, min(h - 1, y1)))
    x2 = int(max(0, min(w, x2)))
    y2 = int(max(0, min(h, y2)))

    if x2 <= x1 or y2 <= y1:
        print("[YOLO] bbox 좌표 이상 → 무시")
        return None

    face = rgb[y1:y2, x1:x2, :]
    if face.size == 0:
        print("[YOLO] crop 결과가 비어 있음")
        return None

    return Image.fromarray(face)  # PIL.Image


def _frame_bytes_to_face_tensor(frame_bytes: bytes) -> Optional[torch.Tensor]:
    """
    1개 프레임(bytes) → 얼굴 crop → [1,3,224,224] 텐서 (or None)
    """
    face_img = _get_face_crop_from_bytes(frame_bytes)
    if face_img is None:
        return None

    tensor = _face_transform(face_img).unsqueeze(0).to(DEVICE)  # [1,3,224,224]
    return tensor


# ====================================================
# 3. 이미지 감정 모델 추론
# ====================================================

def _infer_probs_for_tensor(img_tensor: torch.Tensor) -> List[float]:
    """
    [1,3,224,224] 텐서 → 4클래스 확률 리스트
    """
    _init_models()
    assert _face_model is not None

    with torch.no_grad():
        logits = _face_model(img_tensor)
        probs = F.softmax(logits, dim=1)[0].cpu().numpy()  # [4]

    return [float(p) for p in probs]


# ====================================================
# 4. 🎯 외부에서 사용하는 함수
# ====================================================

def predict_face_probs_from_frames(frame_bytes_list: Optional[List[bytes]]) -> List[float]:
    """
    여러 프레임(bytes 리스트)을 받아, 유효한 얼굴 프레임들에 대해
    각각 예측 → 평균 확률을 반환.

    - 입력: frame_bytes_list: [b'...', b'...', ...]
    - 출력: [기쁨, 분노, 불안, 슬픔] 순서의 확률 리스트 (길이 4)
    """
    if not frame_bytes_list:
        # 프레임이 아예 없으면 균일 분포
        return [0.25, 0.25, 0.25, 0.25]

    all_probs = []
    for fb in frame_bytes_list:
        tensor = _frame_bytes_to_face_tensor(fb)
        if tensor is None:
            continue
        probs = _infer_probs_for_tensor(tensor)
        all_probs.append(probs)

    if not all_probs:
        # YOLO가 얼굴/사람을 하나도 못 찾은 경우
        return [0.25, 0.25, 0.25, 0.25]

    arr = np.array(all_probs)  # [N,4]
    mean_probs = arr.mean(axis=0)  # [4]

    s = float(mean_probs.sum())
    if s > 0:
        mean_probs = mean_probs / s

    return [float(p) for p in mean_probs]
