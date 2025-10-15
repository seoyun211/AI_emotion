import React from 'react';
import { Video, Phone, Heart } from 'lucide-react';

const HomeScreen = ({ setCurrentScreen, setIsCallActive }) => {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-blue-50 to-blue-100 p-8">
      <div className="bg-white rounded-3xl shadow-2xl p-12 max-w-2xl w-full">
        <div className="text-center mb-12">
          <div className="bg-blue-500 w-32 h-32 rounded-full flex items-center justify-center mx-auto mb-6">
            <Video className="w-16 h-16 text-white" />
          </div>
          <h1 className="text-5xl font-bold text-gray-800 mb-4">AI 친구</h1>
          <p className="text-3xl text-gray-600">언제든 이야기하세요</p>
        </div>

        <button
          onClick={() => {
            setIsCallActive(true);
            setCurrentScreen('call');
          }}
          className="w-full bg-green-500 hover:bg-green-600 text-white rounded-2xl py-8 mb-6 flex items-center justify-center gap-4 text-4xl font-bold shadow-lg transition-all transform hover:scale-105"
        >
          <Phone className="w-12 h-12" />
          영상통화 시작
        </button>

        <button
          onClick={() => setCurrentScreen('history')}
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