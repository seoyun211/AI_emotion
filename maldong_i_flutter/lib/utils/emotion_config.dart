// lib/utils/emotion_config.dart
import 'package:flutter/material.dart';

class EmotionConfig {
  static const Map<String, Map<String, dynamic>> emotions = {
    'happy': {
      'icon': '😊',
      'color': Colors.green,
      'text': '기분 좋음',
    },
    'sad': {
      'icon': '😢',
      'color': Colors.blue,
      'text': '슬픔',
    },
    'neutral': {
      'icon': '😐',
      'color': Colors.grey,
      'text': '보통',
    },
  };

  static Map<String, dynamic> getEmotion(String emotion) {
    return emotions[emotion] ?? emotions['neutral']!;
  }

  static String getEmotionIcon(String emotion) {
    return getEmotion(emotion)['icon'];
  }

  static Color getEmotionColor(String emotion) {
    return getEmotion(emotion)['color'];
  }

  static String getEmotionText(String emotion) {
    return getEmotion(emotion)['text'];
  }
}