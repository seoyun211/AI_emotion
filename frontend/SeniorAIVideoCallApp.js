import React, { useState } from 'react';
import HomeScreen from './components/HomeScreen';
import CallScreen from './components/CallScreen';
import HistoryScreen from './components/HistoryScreen';

export default function SeniorAIVideoCallApp() {
  const [currentScreen, setCurrentScreen] = useState('home');
  const [isCallActive, setIsCallActive] = useState(false);
  const [currentEmotion, setCurrentEmotion] = useState('neutral');

  const emotions = {
    happy: { icon: 'Smile', color: 'bg-green-500', text: '기분 좋음' },
    sad: { icon: 'Frown', color: 'bg-blue-500', text: '슬픔' },
    neutral: { icon: 'Meh', color: 'bg-gray-400', text: '보통' },
  };

  const screens = {
    home: <HomeScreen setCurrentScreen={setCurrentScreen} setIsCallActive={setIsCallActive} />,
    call: (
      <CallScreen 
        currentEmotion={currentEmotion}
        setCurrentEmotion={setCurrentEmotion}
        setIsCallActive={setIsCallActive}
        setCurrentScreen={setCurrentScreen}
        emotions={emotions}
      />
    ),
    history: <HistoryScreen setCurrentScreen={setCurrentScreen} emotions={emotions} />,
  };

  return (
    <div className="font-sans">
      {screens[currentScreen]}
    </div>
  );
}