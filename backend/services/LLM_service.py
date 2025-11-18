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