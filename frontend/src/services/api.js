const API_BASE = 'http://localhost:8080/api/v1';

// API 호출 헬퍼
export const apiCall = async (endpoint, options = {}) => {
  try {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error('API Call Failed:', error);
    throw error;
  }
};

// 감정 분석 API
export const analyzeEmotion = async (text, userId = null) => {
  return await apiCall('/predict', {
    method: 'POST',
    body: JSON.stringify({
      text,
      user_id: userId,
    }),
  });
};

// 서버 상태 확인
export const checkServerHealth = async () => {
  try {
    const response = await fetch('http://localhost:8080/health');
    return response.ok;
  } catch {
    return false;
  }
};

// 통화 시작 API
export const startCall = async () => {
  return { success: true, callId: '123' };
};

// 통화 종료 API
export const endCall = async (callId) => {
  return { success: true };
};

// 통화 기록 조회 API
export const getCallHistory = async () => {
  return [
    { id: 1, date: '2024-01-15', emotion: 'happy', duration: '5:30' },
    { id: 2, date: '2024-01-14', emotion: 'neutral', duration: '3:15' }
  ];
};

// 감정 기록 조회 API
export const getEmotionHistory = async () => {
  return [
    { id: 1, date: '2024-01-15', emotion: 'happy' },
    { id: 2, date: '2024-01-14', emotion: 'neutral' }
  ];
};