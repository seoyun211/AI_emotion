# 🧠 AI_emotion (말동이 감정 인식 플랫폼)

> 노인을 위한 감정 인식 기반 AI 돌봄 친구 프로젝트

---

## 📌 프로젝트 개요
AI_emotion은 텍스트, 음성, 이미지 데이터를 분석하여 사용자의 **감정 상태를 실시간으로 인식**하고,
감정에 맞는 반응을 제공하는 **AI 돌봄 서비스 플랫폼**입니다.  
고령층이 쉽게 사용할 수 있는 인터페이스와 따뜻한 대화 경험을 목표로 합니다.

---

## 🧩 주요 기능
- 🗣 **음성 감정 분석** – Tone 및 pitch를 활용한 감정 분류 (기쁨/슬픔/분노 등)
- 💬 **텍스트 감정 분석** – KoBERT 기반 감정 분류
- 📷 **이미지 감정 분석** – 얼굴 표정을 통한 감정 추론 (EfficientNet 기반)
- ⚙️ **Fusion 모델** – 세 가지 모달리티 결과를 종합해 최종 감정 도출
- 💡 **실시간 반응** – FastAPI + Flutter를 통한 실시간 감정 피드백

---

## 🖥️ 시스템 구조
```mermaid
graph TD
    A[Flutter App] -->|Request| B[FastAPI Server]
    B --> C[Text Emotion Model (KoBERT)]
    B --> D[Voice Emotion Model]
    B --> E[Image Emotion Model (EfficientNet)]
    C --> F[Fusion Model]
    D --> F
    E --> F
    F -->|Response: 감정결과| A
