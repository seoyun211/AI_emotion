# backend/services/LLM_service.py
from openai import OpenAI
from config import OPENAI_API_KEY

openai_client = OpenAI(api_key=OPENAI_API_KEY)


def get_llm_response(
    user_text: str,
    emotion: str,
    confidence: float,
    risk_score: float,
    ensemble_detail: dict | None = None,
) -> str:
    """
    말동이 대화 생성기 (감정+텍스트 기반)
    """

    prompt = f"""
당신은 독거노인을 위한 감정 케어 AI '말동이'입니다.
항상 공감하고, 따뜻하게 2~3문장으로 답하세요.

사용자의 현재 감정: {emotion} (신뢰도 {confidence:.2f})
위험도 점수: {risk_score:.2f}

사용자 발화:
"{user_text}"

감정 상태를 잘 이해하고, 따뜻한 존댓말로 답해주세요.
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system",
                 "content": "당신은 독거노인을 위한 따뜻한 돌봄 AI '말동이'입니다. 공감하며 대화합니다."},
                {"role": "user", "content": prompt},
            ]
        )
        return response.choices[0].message.content.strip()

    except Exception as e:
        print(f"[LLM 오류] {e}")
        return "죄송해요. 지금은 말동이가 잘 답변하지 못하겠어요. 조금만 기다려주세요."
