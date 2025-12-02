# 🧠 AI_emotion (말동이 노인 감정 인식 플랫폼)

> 노인을 위한 감정 인식 기반 AI 돌봄 친구 프로젝트

---

## 📌 프로젝트 개요
AI_emotion은 텍스트, 음성, 이미지 데이터를 분석하여 사용자의 **감정 상태를 실시간으로 인식**하고,  
감정에 맞는 반응을 제공하는 **AI 돌봄 서비스 플랫폼**입니다.  
고령층이 쉽게 사용할 수 있는 인터페이스와 따뜻한 대화 경험을 목표로 합니다.

---

## 🧩 주요 기능
- 🗣 **음성 감정 분석**  
  - 음성의 pitch, energy, prosody 특징을 활용한 감정 분류  
  - CNN-BiLSTM 기반 한국어 음성 감정 인식 모델

- 💬 **텍스트 감정 분석**  
  - KoBERT 기반 문장 감정 분류  
  - 사용자의 발화 내용을 텍스트로 변환(STT) 후 감정 인식

- 📷 **이미지 감정 분석**  
  - EfficientNet 기반 얼굴 표정 인식  
  - 카메라로 캡처한 얼굴 이미지를 통해 감정 추론

- 🧮 **앙상블 감정 결정 (Ensemble)**  
  - 이미지 / 텍스트 / 음성 모델이 각각 **4개 감정 클래스에 대한 확률 벡터**를 출력  
  - 모달리티별 가중치(예: 이미지 w_img, 텍스트 w_txt, 음성 w_aud)를 곱해  
    $$ P_{\text{final}} = w_\text{img} \cdot P_\text{img} + w_\text{txt} \cdot P_\text{txt} + w_\text{aud} \cdot P_\text{aud} $$
  - 최종 확률이 가장 높은 감정을 **최종 감정 레이블**로 사용

- 💡 **실시간 반응**  
  - FastAPI 백엔드와 Flutter 앱을 연동  
  - 음성 입력 → 감정 분석(3개 모델 + 앙상블) → LLM 응답 생성 → TTS 음성 합성까지 실시간 파이프라인 구성

---

## 🖥️ 시스템 구조

```mermaid
graph TD
    A[Flutter App] -->|음성·이미지·텍스트 요청| B[FastAPI Server]

    %% 개별 감정 모델
    B --> C[Text Emotion Model - KoBERT]
    B --> D[Voice Emotion Model - Audio CNN-BiLSTM]
    B --> E[Image Emotion Model - EfficientNet]

    %% 모델 출력: 감정 확률 벡터 (4 class)
    C --> G[Ensemble Engine - weighted sum]
    D --> G
    E --> G

    %% 최종 감정 및 후처리
    G --> H[LLM Response]
    H --> I[TTS Synthesis]
    G --> J[Risk Evaluation & Guardian Alert]

    %% 앱으로 응답
    I -->|응답 음성 + 감정 결과| A
    J -->|보호자 알림 데이터| A
