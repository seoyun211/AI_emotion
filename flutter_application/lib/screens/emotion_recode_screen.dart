import 'package:flutter/material.dart';
import 'home_screen.dart';

class EmotionRecordScreen extends StatefulWidget {
  const EmotionRecordScreen({super.key});

  @override
  State<EmotionRecordScreen> createState() => _EmotionRecordScreenState();
}

class _EmotionRecordScreenState extends State<EmotionRecordScreen> {
  int selectedMonth = DateTime.now().month;
  
  // 샘플 데이터
  final Map<int, EmotionData> monthlyData = {
    1: EmotionData(positive: 12, normal: 8, negative: 6, serious: 5),
    2: EmotionData(positive: 15, normal: 7, negative: 4, serious: 2),
    3: EmotionData(positive: 18, normal: 6, negative: 4, serious: 3),
    4: EmotionData(positive: 20, normal: 5, negative: 3, serious: 2),
    5: EmotionData(positive: 16, normal: 8, negative: 4, serious: 2),
    6: EmotionData(positive: 14, normal: 9, negative: 5, serious: 2),
    7: EmotionData(positive: 17, normal: 7, negative: 4, serious: 2),
    8: EmotionData(positive: 19, normal: 6, negative: 3, serious: 2),
    9: EmotionData(positive: 15, normal: 8, negative: 5, serious: 2),
    10: EmotionData(positive: 13, normal: 10, negative: 5, serious: 2),
    11: EmotionData(positive: 16, normal: 8, negative: 4, serious: 2),
    12: EmotionData(positive: 18, normal: 7, negative: 3, serious: 2),
  };

  @override
  Widget build(BuildContext context) {
    final currentData = monthlyData[selectedMonth]!;
    final total = currentData.total;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '감정기록',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '이번 달 기분을 확인해보세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 32),

              // 월 선택
              _buildMonthSelector(),
              const SizedBox(height: 32),

              // 가장 많은 감정
              _buildTopEmotion(currentData),
              const SizedBox(height: 24),

              // 큰 감정 카드들
              _buildBigEmotionCard('긍정', currentData.positive, total, 
                const Color(0xFF66BB6A), Icons.sentiment_very_satisfied, '😊'),
              const SizedBox(height: 16),
              _buildBigEmotionCard('보통', currentData.normal, total, 
                const Color(0xFFFFB74D), Icons.sentiment_satisfied, '😐'),
              const SizedBox(height: 16),
              _buildBigEmotionCard('부정', currentData.negative, total, 
                const Color(0xFF64B5F6), Icons.sentiment_dissatisfied, '😕'),
              const SizedBox(height: 16),
              _buildBigEmotionCard('심각', currentData.serious, total, 
                const Color(0xFFEF5350), Icons.sentiment_very_dissatisfied, '😢'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                selectedMonth = selectedMonth > 1 ? selectedMonth - 1 : 12;
              });
            },
            icon: const Icon(Icons.chevron_left, color: Color(0xFF5D4037), size: 32),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$selectedMonth월',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                selectedMonth = selectedMonth < 12 ? selectedMonth + 1 : 1;
              });
            },
            icon: const Icon(Icons.chevron_right, color: Color(0xFF5D4037), size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmotion(EmotionData data) {
    String topEmotion;
    int topCount;
    Color topColor;
    String emoji;

    if (data.positive >= data.normal && 
        data.positive >= data.negative && 
        data.positive >= data.serious) {
      topEmotion = '긍정';
      topCount = data.positive;
      topColor = const Color(0xFF66BB6A);
      emoji = '😊';
    } else if (data.normal >= data.negative && data.normal >= data.serious) {
      topEmotion = '보통';
      topCount = data.normal;
      topColor = const Color(0xFFFFB74D);
      emoji = '😐';
    } else if (data.negative >= data.serious) {
      topEmotion = '부정';
      topCount = data.negative;
      topColor = const Color(0xFF64B5F6);
      emoji = '😕';
    } else {
      topEmotion = '심각';
      topCount = data.serious;
      topColor = const Color(0xFFEF5350);
      emoji = '😢';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            topColor,
            topColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: topColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            '이번 달 가장 많은 기분',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            topEmotion,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$topCount번',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigEmotionCard(String label, int count, int total, Color color, IconData icon, String emoji) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 이모지
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count번',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '전체의 $percentage%',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmotionData {
  final int positive;
  final int normal;
  final int negative;
  final int serious;

  EmotionData({
    required this.positive,
    required this.normal,
    required this.negative,
    required this.serious,
  });

  int get total => positive + normal + negative + serious;
}