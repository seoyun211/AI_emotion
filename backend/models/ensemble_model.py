# backend/models/ensemble_model.py
# [Copyright Notice]
# 본 프로그램은 멀티모달(Image, Text, Audio) 감정 분석 데이터의 융합을 위해 
# 개발자가 독자적으로 설계한 '신뢰도 가중 기반 소프트 보팅' 및 '복합 감정 위험 지수 산출' 알고리즘을 포함합니다.
# 단순 확률 평균이 아닌, 각 매체의 특성을 고려한 변동 가중치 체계를 적용하였습니다.

from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, List, TypedDict

# 라벨 인덱스: 0=기쁨, 1=분노, 2=불안, 3=슬픔
LABELS: List[str] = ["기쁨", "분노", "불안", "슬픔"]

class ProbabilitiesDict(TypedDict):
    기쁨: float
    분노: float
    불안: float
    슬픔: float

class ModalityResult(TypedDict):
    label: str           # 예측된 감정 라벨 ("기쁨" 등)
    id: int              # 라벨 인덱스 (0~3)
    probabilities: ProbabilitiesDict
    risk_score: float    # 위험도 점수 (0~100)

class EnsembleResult(TypedDict):
    final: ModalityResult
    per_modality: Dict[str, ModalityResult]

@dataclass
class EnsembleEmotionModel:
    """
    [설계 의도]
    이미지, 텍스트, 음성이라는 서로 다른 형태의 데이터를 통합할 때, 
    각 데이터의 감정 전달력과 정확도를 고려하여 '소프트 보팅' 방식으로 결합함.
    """

    # 가중치 결정 근거: 표정(이미지)이 감정 전달의 60% 이상을 차지한다는 심리학적 지표(메라비언 법칙)와 자체 테스트셋의 정확도를 반영하여 설계함.
    # 실제로 이미지 모델이 가장 높은 성능을 보였기에 반영하여 설계함.
    w_img: float = 0.6
    w_text: float = 0.2
    w_audio: float = 0.2

    def __post_init__(self) -> None:
        self._normalize_weights()

    # ---------------- 내부 유틸 ---------------- #

    def _normalize_weights(self) -> None:
        """가중치 합이 1이 되도록 정규화하여 분석 결과의 왜곡을 방지함"""
        total = self.w_img + self.w_text + self.w_audio
        if total <= 0:
            self.w_img, self.w_text, self.w_audio = 0.6, 0.2, 0.2
            total = 1.0
        self.w_img /= total
        self.w_text /= total
        self.w_audio /= total

    @staticmethod
    def _normalize_probs(vec: List[float]) -> List[float]:
        """입력 확률 벡터의 총합을 1로 맞춰 연산의 신뢰성을 확보함."""
        s = sum(vec)
        if s <= 0:
            return [1.0 / len(vec)] * len(vec)
        return [v / s for v in vec]

    @staticmethod
    def _to_prob_dict(vec: List[float]) -> ProbabilitiesDict:
        return {LABELS[i]: float(vec[i]) for i in range(4)}  # type: ignore[return-value]

    @staticmethod
    def _calculate_risk_score(prob_dict: ProbabilitiesDict) -> float:
        """
        [독창적 알고리즘: 고위험 감정 가중치 산출 방식]
        단순 평균이 아닌, 부정 감정(슬픔, 불안)의 가중치를 높여 
        심리적 위험 징후를 조기에 발견할 수 있도록 설계된 위험도 계산 수식임.
        """
        # 고위험 감정 순위: 슬픔 > 불안 > 분노 > 기쁨
        w_sadness = 0.85
        w_anxiety = 0.8
        w_anger = 0.4
        w_joy = 0.1

        score = sum(prob_dict[label] * weights[label] for label in LABELS)
        
        # 불안과 분노가 동시 발생 시 복합 위험 가중치 부여
        # 이는 개발자가 정의한 '복합 감정 위험 시나리오'에 근거함.
        if prob_dict["불안"] > 0.35 and prob_dict["분노"] > 0.35:
            score *= 1.15

        return round(min(score * 100, 100.0), 2)

    # ---------------- 공개 API ---------------- #

    def predict(
        self,
        image_probs: List[float],
        text_probs: List[float],
        audio_probs: List[float],
    ) -> EnsembleResult:
        """
        [핵심 앙상블 로직]
        멀티모달 확률 벡터를 가중 소프트 보팅으로 병합하여 최종 감정을 결정함.
        """

        if len(image_probs) != 4 or len(text_probs) != 4 or len(audio_probs) != 4:
            raise ValueError("입력 확률 벡터는 4개 감정(기쁨/분노/불안/슬픔)을 포함해야 합니다.")

        # 1. 전처리: 데이터 정규화
        v_img = self._normalize_probs(list(image_probs))
        v_text = self._normalize_probs(list(text_probs))
        v_audio = self._normalize_probs(list(audio_probs))

        # 2. 메인 연산: 가중치 기반 소프트 보팅 (Weighted Soft Voting)
        # 개발자가 설계한 w_img, w_text, w_audio 비율에 따라 모달리티 통합
        p_final: List[float] = [
            (self.w_img * v_img[i] + self.w_text * v_text[i] + self.w_audio * v_audio[i])
            for i in range(4)
        ]
        p_final = self._normalize_probs(p_final)

        # 3. 최종 감정 인덱스 및 라벨 결정
        final_idx = max(range(4), key=lambda i: p_final[i])
        final_label = LABELS[final_idx]

        # 4. 각 모달별 최상 감정 인덱스
        img_idx = max(range(4), key=lambda i: v_img[i])
        text_idx = max(range(4), key=lambda i: v_text[i])
        audio_idx = max(range(4), key=lambda i: v_audio[i])

        # 5. 확률 딕셔너리 및 리스크 스코어 계산 후 결과 객체 생성
        result: EnsembleResult = {
            "final": {
                "label": final_label,
                "id": final_idx,
                "probabilities": final_probs,
                "risk_score": self._calculate_risk_score(final_probs),
            },
            "per_modality": {
                "image": {
                    "label": LABELS[img_idx],
                    "id": img_idx,
                    "probabilities": img_probs_dict,
                    "risk_score": self._calculate_risk_score(img_probs_dict),
                },
                "text": {
                    "label": LABELS[text_idx],
                    "id": text_idx,
                    "probabilities": text_probs_dict,
                    "risk_score": self._calculate_risk_score(text_probs_dict),
                },
                "audio": {
                    "label": LABELS[audio_idx],
                    "id": audio_idx,
                    "probabilities": audio_probs_dict,
                    "risk_score": self._calculate_risk_score(audio_probs_dict),
                },
            },
        }
        
        return result  # 최종 결과 반환