import React from 'react';
import { Video, PhoneOff, Bell, User } from 'lucide-react';
import { Smile, Frown, Meh } from 'lucide-react';

const CallScreen = ({ currentEmotion, setCurrentEmotion, setIsCallActive, setCurrentScreen, emotions }) => {
  const getEmotionIcon = (iconName) => {
    const iconMap = {
      Smile: Smile,
      Frown: Frown,
      Meh: Meh,
    };
    return iconMap[iconName] || Meh;
  };

  const EmotionIcon = getEmotionIcon(emotions[currentEmotion].icon);

  return (
    <div className="flex flex-col min-h-screen bg-gray-900">
      {/* 비디오 영역 */}
      <div className="flex-1 relative bg-gradient-to-br from-gray-800 to-gray-900">
        {/* AI 화면 (메인) */}
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="bg-gradient-to-br from-blue-400 to-purple-500 w-64 h-64 rounded-full flex items-center justify-center">
            <User className="w-32 h-32 text-white" />
          </div>
        </div>

        {/* 사용자 화면 (작은 창) */}
        <div className="absolute top-8 right-8 bg-gray-700 w-48 h-36 rounded-2xl shadow-2xl border-4 border-white">
          <div className="w-full h-full bg-gradient-to-br from-gray-600 to-gray-700 rounded-xl flex items-center justify-center">
            <User className="w-16 h-16 text-gray-400" />
          </div>
        </div>

        {/* 감정 상태 표시 */}
        <div className="absolute top-8 left-8 bg-white rounded-2xl px-8 py-4 shadow-2xl">
          <div className="flex items-center gap-4">
            <div className={`${emotions[currentEmotion].color} w-16 h-16 rounded-full flex items-center justify-center`}>
              <EmotionIcon className="w-8 h-8 text-white" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-800">{emotions[currentEmotion].text}</p>
              <p className="text-xl text-gray-600">현재 기분</p>
            </div>
          </div>
        </div>

        {/* 통화 시간 */}
        <div className="absolute top-8 left-1/2 transform -translate-x-1/2 bg-black bg-opacity-60 text-white px-8 py-4 rounded-full text-3xl font-bold">
          15:23
        </div>
      </div>

      {/* 하단 컨트롤 */}
      <div className="bg-gray-800 p-8">
        <div className="flex justify-center gap-8 max-w-2xl mx-auto">
          <button
            onClick={() => setCurrentEmotion('happy')}
            className="bg-gray-700 hover:bg-gray-600 p-6 rounded-full transition-all transform hover:scale-110"
          >
            <Video className="w-10 h-10 text-white" />
          </button>

          <button
            onClick={() => {
              setIsCallActive(false);
              setCurrentScreen('home');
            }}
            className="bg-red-500 hover:bg-red-600 p-8 rounded-full transition-all transform hover:scale-110 shadow-2xl"
          >
            <PhoneOff className="w-14 h-14 text-white" />
          </button>

          <button
            onClick={() => setCurrentEmotion(currentEmotion === 'happy' ? 'sad' : 'happy')}
            className="bg-gray-700 hover:bg-gray-600 p-6 rounded-full transition-all transform hover:scale-110"
          >
            <Bell className="w-10 h-10 text-white" />
          </button>
        </div>

        <p className="text-center text-white text-2xl mt-6">통화 중...</p>
      </div>
    </div>
  );
};

export default CallScreen;