# backend/models/clients/multimodal_client.py

from typing import Dict, Optional
import asyncio
import io
import tempfile

from PIL import Image
import torch
from torchvision import transforms

from models.fusion_model import get_emotion_analyzer

# EfficientNet 학습 때 사용한 전처리와 반드시 맞춰야 함
img_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],  # 코랩에서 다르게 썼다면 여기도 맞춰야 함
        std=[0.229, 0.224, 0.225],
    )
])


class MultimodalClient:
    """
    이미지 + 텍스트 + 음성을 받아서
    fusion_model.EmotionAnalyzer(통합 모델)를 호출하는 클라이언트
    """
    enabled = True

    def __init__(self):
        print("💡 MultimodalClient(Fusion) 로드 중...")
        self.analyzer = get_emotion_analyzer()
        print("✅ MultimodalClient 준비 완료.")

    async def analyze_emotion(
        self,
        text: Optional[str],
        image_bytes: Optional[bytes],
        audio_bytes: Optional[bytes],
        user_id: Optional[str] = None,
    ) -> Dict:
        # 비동기 환경 양보 (필수는 아니지만 좋음)
        await asyncio.sleep(0)

        # 1) 이미지 처리 (지금 /dialogue/speak 에서는 None으로 들어올 예정)
        if image_bytes is not None:
            pil_img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            img_tensor = img_transform(pil_img).unsqueeze(0)  # [1,3,224,224]
        else:
            # 이미지가 없는 경우: 0 텐서로 placeholder
            img_tensor = torch.zeros(1, 3, 224, 224)

        # 2) 오디오 bytes → 임시 wav 파일 path
        audio_path = ""
        if audio_bytes is not None:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                tmp.write(audio_bytes)
                audio_path = tmp.name

        # 3) 통합 모델 실행 (EmotionAnalyzer)
        pred_id, pred_name, probs = self.analyzer.predict(
            image_tensor=img_tensor,
            text_str=text or "",
            audio_path=audio_path,
        )

        # 🎯 라벨 순서 (fusion_model.py 기준)
        # 0: "기쁨", 1: "당황", 2: "분노", 3: "불안", 4: "상처",
        # 5: "슬픔", 6: "중립", 7: "역겨움", 8: "공포", 9: "놀람"
        # 위험 감정 인덱스 (예: 분노/불안/슬픔/공포)
        risk_indices = [2, 3, 5, 8]
        risk_score = float(sum(probs[i] for i in risk_indices))

        return {
            "success": True,
            "model": "fusion_emotion",
            "emotion": pred_name,
            "pred_id": pred_id,
            "probs": probs,                      # 전체 10개 확률
            "confidence": float(max(probs)),     # 최고 확률
            "risk_score": risk_score,
            "needs_alert": risk_score >= 0.6,
        }


# 전역 싱글톤 인스턴스
multimodal_client = MultimodalClient()
