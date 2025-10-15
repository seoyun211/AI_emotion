import React from 'react';
import { AlertCircle, Smile, Frown, Meh } from 'lucide-react';

const HistoryScreen = ({ setCurrentScreen, emotions }) => {
  const records = [
    { date: '2025년 10월 15일', time: '오후 2:30', emotion: 'happy', duration: '25분', alert: false },
    { date: '2025년 10월 14일', time: '오전 10:15', emotion: 'sad', duration: '18분', alert: true },
    { date: '2025년 10월 13일', time: '오후 3:45', emotion: 'neutral', duration: '30분', alert: false },
    { date: '2025년 10월 12일', time: '오전 11:20', emotion: 'happy', duration: '22분', alert: false },
  ];

  const getEmotionIcon = (iconName) => {
    const iconMap = {
      Smile: Smile,
      Frown: Frown,
      Meh: Meh,
    };
    return iconMap[iconName] || Meh;
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-blue-100 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-3xl shadow-2xl p-8 mb-8">
          <h2 className="text-4xl font-bold text-gray-800 mb-2">감정 기록</h2>
          <p className="text-2xl text-gray-600">최근 통화 내역</p>
        </div>

        <div className="space-y-4">
          {records.map((record, idx) => {
            const EmotionIcon = getEmotionIcon(emotions[record.emotion].icon);
            return (
              <div key={idx} className="bg-white rounded-2xl shadow-lg p-6 hover:shadow-xl transition-shadow">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-6">
                    <div className={`${emotions[record.emotion].color} w-20 h-20 rounded-full flex items-center justify-center`}>
                      <EmotionIcon className="w-10 h-10 text-white" />
                    </div>
                    <div>
                      <p className="text-3xl font-bold text-gray-800">{record.date}</p>
                      <p className="text-2xl text-gray-600">{record.time} · {record.duration}</p>
                      <p className="text-2xl text-gray-500 mt-1">{emotions[record.emotion].text}</p>
                    </div>
                  </div>
                  {record.alert && (
                    <div className="bg-orange-100 px-6 py-3 rounded-full flex items-center gap-3">
                      <AlertCircle className="w-8 h-8 text-orange-500" />
                      <span className="text-2xl text-orange-700 font-semibold">보호자 알림됨</span>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <button
          onClick={() => setCurrentScreen('home')}
          className="w-full mt-8 bg-blue-500 hover:bg-blue-600 text-white rounded-2xl py-6 text-3xl font-bold shadow-lg transition-all transform hover:scale-105"
        >
          홈으로 돌아가기
        </button>
      </div>
    </div>
  );
};

export default HistoryScreen;