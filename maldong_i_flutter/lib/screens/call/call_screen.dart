// lib/screens/senior/call_screen.dart
import 'package:flutter/material.dart';
import '../../api/emotion_api.dart';
import '../../utils/emotion_config.dart';

class CallScreen extends StatefulWidget {
  final Function(String) onScreenChange;
  final Function(bool) onCallStatusChange;
  final String currentEmotion;
  final Function(String) onEmotionChange;

  const CallScreen({
    super.key,
    required this.onScreenChange,
    required this.onCallStatusChange,
    required this.currentEmotion,
    required this.onEmotionChange,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  bool isVideoOff = false;
  String transcript = '';

  Future<void> analyzeEmotion(String text) async {
    try {
      final result = await EmotionApi.analyzeEmotion(text, userId: 'test-user');
      print('감정 분석 결과: $result');

      // 감정 상태 업데이트
      final detectedEmotion = _mapEmotionToKey(result['emotion']);
      widget.onEmotionChange(detectedEmotion);

      if (result['needs_alert'] == true) {
        _showAlertDialog(result['emotion']);
      }
    } catch (error) {
      print('감정 분석 실패: $error');
    }
  }

  String _mapEmotionToKey(String koreanEmotion) {
    switch (koreanEmotion) {
      case '기쁨':
        return 'happy';
      case '슬픔':
        return 'sad';
      case '분노':
        return 'sad';
      default:
        return 'neutral';
    }
  }

  void _showAlertDialog(String emotion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('위험 감정 감지'),
            ],
          ),
          content: Text('감지된 감정: $emotion\n보호자에게 알림이 전송되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void simulateSpeechRecognition() {
    final sampleTexts = [
      "오늘 기분이 좋아요",
      "조금 외로워요",
      "아들이 보고 싶어요",
      "날씨가真好네요",
      "혼자 있는게 싫어요"
    ];

    final randomText = sampleTexts[DateTime.now().millisecondsSinceEpoch % sampleTexts.length];
    final newTranscript = '$transcript $randomText';
    
    setState(() {
      transcript = newTranscript;
    });

    analyzeEmotion(newTranscript);
  }

  void endCall() {
    widget.onCallStatusChange(false);
    widget.onScreenChange('home');
  }

  @override
  Widget build(BuildContext context) {
    final emotionConfig = EmotionConfig.getEmotion(widget.currentEmotion);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/남자아바타.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        const Text(
                          '말동이와 대화중...',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: simulateSpeechRecognition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '대화 시뮬레이션 (백엔드 테스트)',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (transcript.isNotEmpty)
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          transcript,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: emotionConfig['color'],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                emotionConfig['icon'],
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emotionConfig['text'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Text(
                                '현재 기분',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFF374151),
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: isMuted ? Icons.mic_off : Icons.mic,
                    isActive: !isMuted,
                    onPressed: () => setState(() => isMuted = !isMuted),
                  ),
                  const SizedBox(width: 24),
                  _buildControlButton(
                    icon: isVideoOff ? Icons.videocam_off : Icons.videocam,
                    isActive: !isVideoOff,
                    onPressed: () => setState(() => isVideoOff = !isVideoOff),
                  ),
                  const SizedBox(width: 24),
                  _buildEndCallButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4B5563) : Colors.red,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: endCall,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}