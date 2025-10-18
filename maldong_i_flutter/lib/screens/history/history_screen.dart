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
      '분노': 'sad',
    };
    final emotionKey = koreanToKey[emotion] ?? 'neutral';
    return EmotionConfig.getEmotionColor(emotionKey);
  }

  Color _getEmotionTextColor(String emotion) {
    final koreanToKey = {
      '기쁨': 'happy',
      '슬픔': 'sad',
      '분노': 'sad',
    };
    final emotionKey = koreanToKey[emotion] ?? 'neutral';
    return EmotionConfig.getEmotionColor(emotionKey);
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
                              child: Text(
                                '기록이 없습니다',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade500,
                                ),
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
                                return Container(
                                  color: Colors.transparent,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {},
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _getEmotionBackgroundColor(
                                                            record['emotion']),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    record['emotion'] ?? '중립',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          _getEmotionTextColor(
                                                              record[
                                                                  'emotion']),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatDate(record['date']),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            if (record['text_content'] != null)
                                              Text(
                                                record['text_content'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF374151),
                                                  height: 1.4,
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '위험도: ${((record['risk_score'] ?? 0) * 100).round()}%',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
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