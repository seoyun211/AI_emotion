// lib/screens/common/history_screen.dart
import 'package:flutter/material.dart';
import '../../api/emotion_api.dart';
import '../../utils/emotion_config.dart';

class HistoryScreen extends StatefulWidget {
  final Function(String) onScreenChange;

  const HistoryScreen({
    super.key,
    required this.onScreenChange,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> emotionHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEmotionHistory();
  }

  Future<void> loadEmotionHistory() async {
    try {
      final data = await EmotionApi.getEmotionHistory();
      setState(() {
        emotionHistory = data;
        isLoading = false;
      });
    } catch (error) {
      print('기록 불러오기 실패: $error');
      setState(() {
        emotionHistory = [];
        isLoading = false;
      });
    }
  }

  Color _getEmotionBackgroundColor(String emotion) {
    final koreanToKey = {
      '기쁨': 'happy',
      '슬픔': 'sad',
      '분노': 'angry',
      'happy': 'happy',
      'sad': 'sad',
      'angry': 'angry',
      'neutral': 'neutral',
    };
    final emotionKey = koreanToKey[emotion] ?? 'neutral';
    final emotionConfig = EmotionConfig.getEmotion(emotionKey);
    return emotionConfig['color'] ?? Colors.grey;
  }

  Color _getEmotionTextColor(String emotion) {
    // 텍스트 색상은 일반적으로 흰색으로 통일
    return Colors.white;
  }

  String _getEmotionDisplayName(String emotion) {
    final koreanNames = {
      'happy': '기쁨',
      'sad': '슬픔',
      'angry': '분노',
      'neutral': '중립',
      '기쁨': '기쁨',
      '슬픔': '슬픔',
      '분노': '분노',
    };
    return koreanNames[emotion] ?? emotion;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E8FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onScreenChange('home'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF374151),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '감정 기록',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '나의 감정 변화를 확인해보세요',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : emotionHistory.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '아직 기록이 없습니다',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '영상통화를 시작해보세요!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: emotionHistory.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Colors.grey.shade100,
                              ),
                              itemBuilder: (context, index) {
                                final record = emotionHistory[index];
                                final emotion = record['emotion']?.toString() ?? 'neutral';
                                final duration = record['duration']?.toString() ?? '';
                                final summary = record['summary']?.toString() ?? '';
                                
                                return Container(
                                  color: Colors.transparent,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        // 기록 상세보기 기능 (선택사항)
                                        print('기록 선택: $record');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getEmotionBackgroundColor(emotion),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    _getEmotionDisplayName(emotion),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: _getEmotionTextColor(emotion),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatDate(record['date']?.toString() ?? ''),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            if (summary.isNotEmpty)
                                              Text(
                                                summary,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF374151),
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  duration.isNotEmpty ? duration : '시간 정보 없음',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}년 ${date.month}월 ${date.day}일';
    } catch (e) {
      return dateString;
    }
  }
}