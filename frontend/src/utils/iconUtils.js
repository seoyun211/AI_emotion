import { Smile, Frown, Meh } from 'lucide-react';

export const getEmotionIcon = (iconName) => {
  const iconMap = {
    Smile: Smile,
    Frown: Frown,
    Meh: Meh,
  };
  return iconMap[iconName] || Meh;
};

export const emotionConfig = {
  happy: { icon: 'Smile', color: 'bg-green-500', text: '기분 좋음' },
  sad: { icon: 'Frown', color: 'bg-blue-500', text: '슬픔' },
  neutral: { icon: 'Meh', color: 'bg-gray-400', text: '보통' },
};