# backend/models/ensemble_model.py
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
    이미지 / 텍스트 / 음성 모델이 출력한
    4개 감정 확률을 가중치 소프트보팅으로 결합하는 앙상블 모델.

    - 각 모달리티 확률 벡터는 길이 4, 순서: [기쁨, 분노, 불안, 슬픔]
    """

    w_img: float = 0.6
    w_text: float = 0.2
    w_audio: float = 0.2

    def __post_init__(self) -> None:
        self._normalize_weights()

    # ---------------- 내부 유틸 ---------------- #

    def _normalize_weights(self) -> None:
        """가중치 합이 1이 되도록 정규화."""
        total = self.w_img + self.w_text + self.w_audio
        if total <= 0:
            self.w_img, self.w_text, self.w_audio = 0.6, 0.2, 0.2
            total = 1.0
        self.w_img /= total
        self.w_text /= total
        self.w_audio /= total

    @staticmethod
    def _normalize_probs(vec: List[float]) -> List[float]:
        """확률 합이 1이 되도록 정규화 (안전장치)."""
        s = sum(vec)
        if s <= 0:
            return [1.0 / len(vec)] * len(vec)
        return [v / s for v in vec]

    @staticmethod
    def _to_prob_dict(vec: List[float]) -> ProbabilitiesDict:
        """[4] 리스트 → 라벨 이름 dict로 변환."""
        return {LABELS[i]: float(vec[i]) for i in range(4)}  # type: ignore[return-value]

    @staticmethod
    def _calculate_risk_score(prob_dict: ProbabilitiesDict) -> float:
        """
        감정 확률 기반 위험도 점수 계산 (0.0 ~ 100.0)
        
        [가중치 설정 변경]
          - 슬픔: 0.85 (가장 높음)
          - 불안: 0.8
          - 분노: 0.4
          - 기쁨: 0.1
        """
        w_sadness = 0.85
        w_anxiety = 0.8
        w_anger = 0.4
        w_joy = 0.1

        score = (
            prob_dict["슬픔"] * w_sadness
            + prob_dict["불안"] * w_anxiety
            + prob_dict["분노"] * w_anger
            + prob_dict["기쁨"] * w_joy
        )
        
        # 0~1 사이의 score를 100점 만점으로 환산
        return round(score * 100, 2)

    # ---------------- 공개 API ---------------- #

    def predict(
        self,
        image_probs: List[float],
        text_probs: List[float],
        audio_probs: List[float],
    ) -> EnsembleResult:
        """
        Parameters
        ----------
        image_probs, text_probs, audio_probs : list[float]
            길이 4 확률 벡터, 순서: [기쁨, 분노, 불안, 슬픔]

        Returns
        -------
        EnsembleResult
          {
            "final": { "label": ..., "id": ..., "probabilities": ..., "risk_score": ... },
            "per_modality": {
              "image": { ... }, "text": { ... }, "audio": { ... }
            }
          }
        """

        if len(image_probs) != 4 or len(text_probs) != 4 or len(audio_probs) != 4:
            raise ValueError("각 확률 벡터는 길이 4여야 합니다. (기쁨/분노/불안/슬픔)")

        # 1. 확률 정규화
        v_img = self._normalize_probs(list(image_probs))
        v_text = self._normalize_probs(list(text_probs))
        v_audio = self._normalize_probs(list(audio_probs))

        # 2. 가중치 기반 소프트보팅
        p_final: List[float] = []
        for i in range(4):
            val = (
                self.w_img * v_img[i]
                + self.w_text * v_text[i]
                + self.w_audio * v_audio[i]
            )
            p_final.append(val)

        p_final = self._normalize_probs(p_final)

        # 3. 최종 감정 (index = id)
        final_idx = max(range(4), key=lambda i: p_final[i])
        final_label = LABELS[final_idx]

        # 4. 각 모달별 최상 감정 인덱스
        img_idx = max(range(4), key=lambda i: v_img[i])
        text_idx = max(range(4), key=lambda i: v_text[i])
        audio_idx = max(range(4), key=lambda i: v_audio[i])

        # 5. 확률 딕셔너리 및 리스크 스코어 계산
        final_probs = self._to_prob_dict(p_final)
        img_probs = self._to_prob_dict(v_img)
        text_probs = self._to_prob_dict(v_text)
        audio_probs = self._to_prob_dict(v_audio)

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
                    "probabilities": img_probs,
                    "risk_score": self._calculate_risk_score(img_probs),
                },
                "text": {
                    "label": LABELS[text_idx],
                    "id": text_idx,
                    "probabilities": text_probs,
                    "risk_score": self._calculate_risk_score(text_probs),
                },
                "audio": {
                    "label": LABELS[audio_idx],
                    "id": audio_idx,
                    "probabilities": audio_probs,
                    "risk_score": self._calculate_risk_score(audio_probs),
                },
            },
        }
        return result