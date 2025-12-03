# backend/models/clients/face_client.py
from __future__ import annotations

from typing import List, Optional
from pathlib import Path
from io import BytesIO

import cv2
import numpy as np
from PIL import Image

import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.transforms as transforms
from torchvision.models import efficientnet_b0

import mediapipe as mp


# ==============================
# 공통 설정
# ==============================
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 4클래스 (모델 학습 라벨과 동일)
EMOTIONS_KO = ['기쁨', '분노', '불안', '슬픔']
EMOTIONS_EN = ['happy', 'angry', 'anxious', 'sad']

# 앙상블 LABELS와 반드시 순서 일치해야 함!
FOUR_CLASS_LABELS = ['기쁨', '분노', '불안', '슬픔']

# 🔧 모델 경로 (프로젝트 구조에 맞게 수정)
BASE_DIR = Path(__file__).resolve().parents[2]   # backend/models/clients → project_root
IMAGE_MODEL_PATH = BASE_DIR / "model_weights" / "expression_model_4cls.pt"
# ↑ 실제 저장된 파일명에 맞게 이름만 바꿔주면 됨


# ==============================
# 1) 모델/검출기/transform 캐시
# ==============================
_model: Optional[nn.Module] = None
_face_detector = None
_transform = None


def _get_transform() -> transforms.Compose:
    """EfficientNet-B0 학습 때 사용한 전처리와 동일하게 맞추기"""
    global _transform
    if _transform is None:
        _transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
        ])
    return _transform


def _get_face_detector():
    """Mediapipe 얼굴 검출기 (lazy init)"""
    global _face_detector
    if _face_detector is None:
        _face_detector = mp.solutions.face_detection.FaceDetection(
            model_selection=1,
            min_detection_confidence=0.5,
        )
    return _face_detector


def load_expression_model(
    model_path: Path = IMAGE_MODEL_PATH,
    num_classes: int = 4,
) -> nn.Module:
    """
    EfficientNet-B0 + 4클래스 표정 인식 모델 로드
    """
    global _model
    if _model is not None:
        return _model

    model = efficientnet_b0(weights=None)   # 학습 가중치로 덮어쓸 것이므로 None
    in_features = model.classifier[1].in_features
    model.classifier[1] = nn.Linear(in_features, num_classes)

    state = torch.load(str(model_path), map_location=DEVICE)
    model.load_state_dict(state)

    model.to(DEVICE)
    model.eval()

    print(f"[face_client] 이미지 모델 로드 완료: {model_path}")
    _model = model
    return model


# ==============================
# 2) 얼굴 검출 + 프레임 전처리
# ==============================
def _detect_face_bbox(rgb_frame: np.ndarray, scale: float = 0.5):
    """
    rgb_frame: [H,W,3], RGB np.ndarray
    return: (x1,y1,x2,y2) 또는 None
    """
    h, w, _ = rgb_frame.shape
    detector = _get_face_detector()

    small_rgb = cv2.resize(rgb_frame, (0, 0), fx=scale, fy=scale)
    results = detector.process(small_rgb)

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

    return (x1, y1, x2, y2)


def _frame_bytes_to_face_tensor(frame_bytes: bytes) -> Optional[torch.Tensor]:
    """
    Flutter/클라이언트에서 받은 프레임 bytes를:
    1) 이미지 디코딩 (BGR)
    2) RGB 변환
    3) Mediapipe로 얼굴 bbox 검출
    4) 얼굴 crop → PIL → EfficientNet transform
    5) [1,3,224,224] 텐서로 반환
    얼굴을 못 찾으면 None 반환
    """
    # bytes → np.ndarray(BGR)
    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if frame_bgr is None:
        return None

    rgb_frame = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
    bbox = _detect_face_bbox(rgb_frame, scale=0.5)
    if bbox is None:
        return None

    x1, y1, x2, y2 = bbox
    face_img = Image.fromarray(rgb_frame[y1:y2, x1:x2])

    transform = _get_transform()
    tensor = transform(face_img).unsqueeze(0).to(DEVICE)  # [1,3,224,224]
    return tensor


# ==============================
# 3) 🔥 앙상블용 핵심 함수
# ==============================
def predict_face_probs_from_frames(frame_bytes_list: List[bytes]) -> List[float]:
    """
    여러 프레임 bytes 리스트를 받아:
    1) 각 프레임에 대해 얼굴 검출 + EfficientNet 4클래스 확률 계산
    2) 프레임들 확률을 평균
    3) [기쁨, 분노, 불안, 슬픔] 순서의 길이 4 확률 리스트 반환

    frame_bytes_list: 보통 5개 프레임 권장 (비어있으면 균일 분포 반환)
    """
    model = load_expression_model()

    if len(frame_bytes_list) == 0:
        return [0.25, 0.25, 0.25, 0.25]
    # 필요하면 5장으로 제한
    if len(frame_bytes_list) > 5:
        frame_bytes_list = frame_bytes_list[:5]

    probs_accum = None
    valid_count = 0

    for frame_bytes in frame_bytes_list:
        img_tensor = _frame_bytes_to_face_tensor(frame_bytes)
        if img_tensor is None:
            continue

        with torch.no_grad():
            logits = model(img_tensor)           # [1,4]
            probs = F.softmax(logits, dim=1)[0]  # [4]
            probs_np = probs.cpu().numpy()

        if probs_accum is None:
            probs_accum = probs_np
        else:
            probs_accum += probs_np

        valid_count += 1

    # 얼굴을 하나도 못 찾으면 균일 분포
    if probs_accum is None or valid_count == 0:
        return [0.25, 0.25, 0.25, 0.25]

    avg_probs_4 = (probs_accum / valid_count).tolist()  # [4]

    # 안전하게 한 번 더 정규화
    s = sum(avg_probs_4)
    if s <= 0:
        return [0.25, 0.25, 0.25, 0.25]
    avg_probs_4 = [p / s for p in avg_probs_4]

    return avg_probs_4
