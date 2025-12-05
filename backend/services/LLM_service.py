# backend/services/llm_service.py
from openai import OpenAI
from config import OPENAI_API_KEY

openai_client = OpenAI(api_key=OPENAI_API_KEY)

def get_llm_response(user_text: str) -> str:
    """사용자 텍스트를 받아 LLM 응답을 생성합니다."""
    try:
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "당신은 독거노인을 위한 따뜻한 대화형 AI '말동이'입니다. 친절하고 짧게 대화해주세요."},
                {"role": "user", "content": user_text}
            ]
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"LLM 오류: {e}")
        return "죄송합니다. 답변을 생성하지 못했습니다."

# 🔹 감정까지 포함해서 말동이 답변 생성
def get_llm_response_with_emotion(emotion_name: str, user_text: str) -> str:
    prompt = f"""
사용자의 현재 감정은 '{emotion_name}' 입니다.
사용자가 이렇게 말했습니다: "{user_text}"

너는 독거노인을 돌보는 감정 케어 AI '말동이'야.
이 감정 상태를 잘 공감하고, 2~3문장 안에서 따뜻하게 답해줘.
"""
    try:
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",    # 필요하면 gpt-4.1-mini 등으로 변경
            messages=[
                {"role": "system", "content": "당신은 독거노인을 위한 따뜻한 대화형 AI '말동이'입니다. 존댓말로 따뜻하게 대화해주세요."},
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"LLM 오류(감정 버전): {e}")
        return "죄송합니다. 지금은 말동이가 답변을 잘 못하겠어요. 잠시 후 다시 시도해 주세요."