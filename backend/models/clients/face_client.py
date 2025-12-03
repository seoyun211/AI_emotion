# backend/models/clients/face_client.py
from __future__ import annotations

from typing import List
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F
from PIL import Image
from torchvision import transforms
from torchvision.models import efficientnet_b0, EfficientNet_B0_Weights


# ------------------------------
# 공통 설정
# ------------------------------
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 라벨 순서: 0:기쁨, 1:분노, 2:불안, 3:슬픔
LABELS: List[str] = ["기쁨", "분노", "불안", "슬픔"]


# ------------------------------
# 모델 가중치 경로
#   - 백엔드 기준 경로로 수정
#   - project_root/model_weights/image_model.pt 이런 식으로 두는 걸 추천
# ------------------------------
BASE_DIR = Path(__file__).resolve().parents[2]   # backend/models/clients → parents[2] = project_root
IMAGE_MODEL_PATH = BASE_DIR / "model_weights" / "image_model.pt"
# ↑ 필요하면 파일명만 네가 실제 저장한 걸로 바꿔줘
#    예: "image_model.pt"


# =====================================================
# 1) 이미지 전처리 transform (ExpressionDataset과 동일)
# =====================================================
def _get_image_transform() -> transforms.Compose:
    """
    ExpressionDataset에서 사용한 전처리와 동일:
    - Resize(224,224)
    - ToTensor()
    (학습 때 Normalize를 썼다면 여기에도 동일하게 추가해야 함)
    """
    return transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        # 🔴 학습 시 Normalize를 썼다면 주석 해제하고 mean/std 맞춰줘
        # transforms.Normalize(mean=[0.485, 0.456, 0.406],
        #                      std=[0.229, 0.224, 0.225]),
    ])


# =====================================================
# 2) EfficientNet-B0 기반 표정 인식 모델 로드
# =====================================================
_image_model: nn.Module | None = None  # 캐싱용


def load_expression_model(
    model_path: Path = IMAGE_MODEL_PATH,
    num_classes: int = 4,
) -> nn.Module:
    """
    EfficientNet-B0 백본 + 학습된 가중치 로드.
    """
    global _image_model
    if _image_model is not None:
        return _image_model

    # EfficientNet-B0 생성
    weights = EfficientNet_B0_Weights.DEFAULT
    model = efficientnet_b0(weights=weights)

    # classifier의 마지막 Linear를 4클래스로 교체
    in_features = model.classifier[1].in_features
    model.classifier[1] = nn.Linear(in_features, num_classes)

    # 학습된 state_dict 로드
    state = torch.load(str(model_path), map_location=DEVICE)
    model.load_state_dict(state)

    model.to(DEVICE)
    model.eval()

    print(f"[INFO][face_client] 이미지 모델 로드 완료: {model_path}")
    _image_model = model
    return model


# =====================================================
# 3) 전처리 함수 (이미지 파일 → 텐서)
# =====================================================
def _preprocess_image(image_path: str) -> torch.Tensor:
    """
    이미지 파일 경로를 받아
    - PIL Image 로 로드
    - ExpressionDataset과 동일한 transform 적용
    - [1,3,224,224] 텐서로 변환 후 DEVICE로 이동
    """
    transform = _get_image_transform()

    img = Image.open(image_path).convert("RGB")
    tensor = transform(img)          # [3,224,224]
    tensor = tensor.unsqueeze(0)     # [1,3,224,224]
    tensor = tensor.to(DEVICE)
    return tensor


# =====================================================
# 4) 앙상블용 확률 반환 함수 (핵심)
# =====================================================
def predict_face_probs(image_path: str) -> List[float]:
    """
    앙상블 모델에서 호출할 최종 API.

    Parameters
    ----------
    image_path : str
        로컬 이미지 파일 경로

    Returns
    -------
    probs : list[float] 길이 4
        [기쁨, 분노, 불안, 슬픔] 순서의 클래스별 확률
    """
    model = load_expression_model()
    img_tensor = _preprocess_image(image_path)  # [1,3,224,224]

    with torch.no_grad():
        logits = model(img_tensor)              # [1,4]
        prob_vec = F.softmax(logits, dim=1)[0].cpu().numpy().tolist()

    # prob_vec: [p_기쁨, p_분노, p_불안, p_슬픔] (라벨 인덱스 0~3에 대응)
    return prob_vec
