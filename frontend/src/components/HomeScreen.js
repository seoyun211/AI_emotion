import React, { useState, useEffect } from 'react';
import { Video, Phone, Heart } from 'lucide-react';
import { analyzeEmotion, checkServerHealth } from '../services/api.js';

const HomeScreen = ({ setCurrentScreen, setIsCallActive }) => {
  const [serverOnline, setServerOnline] = useState(false);

  useEffect(() => {
    checkServerStatus();
  }, []);

  const checkServerStatus = async () => {
    const isOnline = await checkServerHealth();
    setServerOnline(isOnline);
  };

  // 영상통화 시작 시 백엔드에 알림
  const handleStartCall = () => {
    // 백엔드에 통화 시작 알림 (선택사항)
    if (serverOnline) {
      // 여기에 통화 시작 API 호출 추가 가능
      console.log('영상통화 시작 - 백엔드에 알림');
    }
    
    setIsCallActive(true);
    setCurrentScreen('call');
  };

  // 기록 보기 시 백엔드에서 데이터 로드
  const handleViewHistory = () => {
    if (serverOnline) {
      // 기록 화면에서 백엔드 데이터 로드
      console.log('기록 조회 - 백엔드 데이터 로드');
    }
    setCurrentScreen('history');
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-blue-50 to-blue-100 p-8">
      <div className="bg-white rounded-3xl shadow-2xl p-12 max-w-2xl w-full">
        <div className="text-center mb-12">
          <div className="bg-blue-500 w-32 h-32 rounded-full flex items-center justify-center mx-auto mb-6">
            <Video className="w-16 h-16 text-white" />
          </div>
          <h1 className="text-5xl font-bold text-gray-800 mb-4">말동이</h1>
          <p className="text-3xl text-gray-600">언제든 이야기하세요</p>
          
          {/* 서버 상태만 간단히 표시 */}
          <div className={`mt-4 text-sm ${serverOnline ? 'text-green-600' : 'text-red-600'}`}>
            {serverOnline ? '✅ 서버 연결됨' : '❌ 서버 연결 안됨'}
          </div>
        </div>

        {/* 원본 UI 그대로 유지 */}
        <button
          onClick={handleStartCall}
          className="w-full bg-green-500 hover:bg-green-600 text-white rounded-2xl py-8 mb-6 flex items-center justify-center gap-4 text-4xl font-bold shadow-lg transition-all transform hover:scale-105"
        >
          <Phone className="w-12 h-12" />
          영상통화 시작
        </button>

        <button
          onClick={handleViewHistory}
          className="w-full bg-blue-500 hover:bg-blue-600 text-white rounded-2xl py-8 flex items-center justify-center gap-4 text-4xl font-bold shadow-lg transition-all transform hover:scale-105"
        >
          <Heart className="w-12 h-12" />
          감정 기록 보기
        </button>
      </div>
    </div>
  );
};

export default HomeScreen;