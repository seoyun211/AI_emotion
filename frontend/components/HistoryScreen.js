import React, { useState, useEffect } from 'react';
import { ArrowLeft, Calendar, TrendingUp } from 'lucide-react';
import { getEmotionHistory } from '../services/api';

const HistoryScreen = ({ setCurrentScreen }) => {
  const [emotionHistory, setEmotionHistory] = useState([]);

  useEffect(() => {
    loadEmotionHistory();
  }, []);

  const loadEmotionHistory = async () => {
    try {
      // 백엔드에서 데이터 로드
      const response = await getEmotionHistory('test-user', 10);
      setEmotionHistory(response.history || []);
    } catch (error) {
      console.error('기록 불러오기 실패:', error);
      // 에러 시 빈 배열 유지
      setEmotionHistory([]);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-purple-50 to-purple-100 p-8">
      <div className="max-w-4xl mx-auto">
        {/* 원본 헤더 유지 */}
        <div className="flex items-center gap-4 mb-8">
          <button
            onClick={() => setCurrentScreen('home')}
            className="p-3 bg-white rounded-2xl shadow-lg hover:bg-gray-50 transition-colors"
          >
            <ArrowLeft size={24} className="text-gray-700" />
          </button>
          <div>
            <h1 className="text-4xl font-bold text-gray-800">감정 기록</h1>
            <p className="text-gray-600">나의 감정 변화를 확인해보세요</p>
          </div>
        </div>

        {/* 원본 UI 구조 유지 - 백엔드 데이터만 표시 */}
        <div className="bg-white rounded-2xl shadow-lg overflow-hidden">
          {emotionHistory.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              {emotionHistory.length === 0 ? '기록이 없습니다' : '백엔드에서 데이터를 불러오는 중...'}
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {emotionHistory.map((record, index) => (
                <div key={index} className="p-6 hover:bg-gray-50 transition-colors">
                  <div className="flex items-center gap-3 mb-2">
                    <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                      record.emotion === '기쁨' ? 'bg-green-100 text-green-800' :
                      record.emotion === '슬픔' ? 'bg-blue-100 text-blue-800' :
                      record.emotion === '분노' ? 'bg-red-100 text-red-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {record.emotion}
                    </span>
                    <span className="text-sm text-gray-500">
                      {new Date(record.created_at).toLocaleDateString('ko-KR')}
                    </span>
                  </div>
                  <p className="text-gray-700">{record.text_content}</p>
                  <div className="mt-2 text-sm text-gray-500">
                    위험도: {Math.round(record.risk_score * 100)}%
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default HistoryScreen;