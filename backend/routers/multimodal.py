# backend/routers/multimodal.py

from fastapi import APIRouter, HTTPException
from datetime import datetime
import os

from PIL import Image
import torchvision.transforms as T

from models.schemas import MultiModalEmotionRequest, MultiModalEmotionResponse
from models.fusion_model import get_emotion_analyzer
from services.llm_service import get_llm_response_with_emotion

router = APIRouter(prefix="/api/v2", tags=["멀티모달 감정 분석"])

# 학습 때와 동일한 이미지 transform
image_transform = T.Compose([
    T.Resize((224, 224)),
    T.ToTensor(),
    T.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225]),
])

@router.post("/multimodal/predict", response_model=MultiModalEmotionResponse)
async def multimodal_predict(req: MultiModalEmotionRequest):
    # 1) 파일 경로 체크
    if not os.path.exists(req.image_path):
        raise HTTPException(status_code=400, detail=f"image_path not found: {req.image_path}")
    if not os.path.exists(req.audio_path):
        raise HTTPException(status_code=400, detail=f"audio_path not found: {req.audio_path}")

    # 2) 이미지 로드 & 전처리
    img = Image.open(req.image_path).convert("RGB")
    img_tensor = image_transform(img).unsqueeze(0)  # [1,3,224,224]

    # 3) 멀티모달 모델로 감정 예측
    analyzer = get_emotion_analyzer()
    emotion_id, emotion_name, probs = analyzer.predict(
        image_tensor=img_tensor,
        text_str=req.text,
        audio_path=req.audio_path,
    )

    # 4) LLM으로 말동이 답변 생성
    llm_reply = get_llm_response_with_emotion(emotion_name, req.text)

    # 5) 응답 만들기 (지금은 DB 저장은 생략, 나중에 emotion_service랑 통합 가능)
    return MultiModalEmotionResponse(
        emotion_id=emotion_id,
        emotion=emotion_name,
        probs=probs,
        llm_reply=llm_reply,
        user_id=req.user_id,
        timestamp=datetime.now(),
    )
