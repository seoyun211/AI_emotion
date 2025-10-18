import React, { useState } from 'react';
import { PhoneOff, Mic, MicOff, Video, VideoOff } from 'lucide-react';
import { analyzeEmotion } from '../services/api.js';

const CallScreen = ({ setCurrentScreen, setIsCallActive }) => {
  const [isMuted, setIsMuted] = useState(false);
  const [isVideoOff, setIsVideoOff] = useState(false);
  const [transcript, setTranscript] = useState('');

  // 음성 인식 시뮬레이션
  const simulateSpeechRecognition = async () => {
    const sampleTexts = [
      "오늘 기분이 좋아요",
      "조금 외로워요",
      "아들이 보고 싶어요",
      "날씨가真好네요",
      "혼자 있는게 싫어요"
    ];

    const randomText = sampleTexts[Math.floor(Math.random() * sampleTexts.length)];
    const newTranscript = transcript + ' ' + randomText;
    setTranscript(newTranscript);

    try {
      const result = await analyzeEmotion(newTranscript);
      console.log('감정 분석 결과:', result);

      if (result.needs_alert) {
        alert(`🚨 위험 감정 감지: ${result.emotion}`);
      }
    } catch (error) {
      console.error('감정 분석 실패:', error);
    }
  };

  const endCall = () => {
    setIsCallActive(false);
    setCurrentScreen('home');
  };

  return (
    <div className="flex flex-col min-h-screen bg-gray-900">
      {/* 아바타 이미지 화면 꽉 채우기 */}
      <div className="flex-1 relative">
        <img
          src={process.env.PUBLIC_URL + '/static/images/남자아바타.png'}
          alt="아바타"
          className="w-full h-full object-cover"
        />

        {/* 아바타 위 텍스트 및 시뮬레이션 버튼 */}
        <div className="absolute bottom-32 w-full text-center text-white">
          <p className="text-2xl">말동이와 대화중...</p>
          <button
            onClick={simulateSpeechRecognition}
            className="mt-4 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          >
            대화 시뮬레이션 (백엔드 테스트)
          </button>
        </div>
      </div>

      {/* 하단 컨트롤 바 */}
      <div className="bg-gray-800 p-6 flex justify-center gap-6">
        <button
          onClick={() => setIsMuted(!isMuted)}
          className={`p-4 rounded-full ${isMuted ? 'bg-red-500' : 'bg-gray-600'} text-white`}
        >
          {isMuted ? <MicOff size={24} /> : <Mic size={24} />}
        </button>

        <button
          onClick={() => setIsVideoOff(!isVideoOff)}
          className={`p-4 rounded-full ${isVideoOff ? 'bg-red-500' : 'bg-gray-600'} text-white`}
        >
          {isVideoOff ? <VideoOff size={24} /> : <Video size={24} />}
        </button>

        <button
          onClick={endCall}
          className="p-4 bg-red-500 text-white rounded-full"
        >
          <PhoneOff size={24} />
        </button>
      </div>
    </div>
  );
};

export default CallScreen;
