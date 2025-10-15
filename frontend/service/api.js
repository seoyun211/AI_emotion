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