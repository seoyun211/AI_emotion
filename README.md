# 🧡 말동이 (AI_emotion)
> “따뜻한 대화와 감정 인식으로 마음을 돌보는 AI 친구”

---

## 📌 프로젝트 개요
AI_emotion은 텍스트, 음성, 이미지 데이터를 분석하여 사용자의 **감정 상태를 실시간으로 인식**하고,
감정에 맞는 반응을 제공하는 **대화형 AI** 애플리케이션 입니다.  
고령층이 쉽게 사용할 수 있는 인터페이스와 따뜻한 대화 경험을 목표로 합니다.

---

## 💡 주요 기능
| 기능 | 설명 |
|------|------|
| 🗣 **AI 말동무** | 사용자의 목소리를 인식해 자연스러운 대화 제공 |
| 😊 **감정 인식 (멀티모달)** | 텍스트 + 음성 + 이미지를 함께 분석해 감정 추론 |
| 💬 **맞춤형 피드백** | 감정 상태에 따라 대화·표정·음성 반응 자동 조정 |
| 🧠 **Fusion AI 모델** | 세 감정 모델 결과를 종합해 최종 감정 도출 |
| 💾 **감정 로그 관리** | MySql에 감정 변화 기록 및 시각화 |
| 💖 **노인 친화형 UI** | 큰 글씨, 따뜻한 색상, 단순한 조작으로 누구나 쉽게 사용 |

---

## 🧠 시스템 구조

```mermaid
graph TD
    A[Flutter App (말동이)] --> B[FastAPI Server]
    B --> C[Text Emotion Model (KoBERT)]
    B --> D[Voice Emotion Model (CNN + MelSpectrogram)]
    B --> E[Image Emotion Model (EfficientNetB0)]
    C --> F[Fusion Model]
    D --> F
    E --> F
    F --> A
    B --> G[(MongoDB Atlas)]
