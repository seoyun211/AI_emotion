import 'package:flutter/material.dart';
import 'guardian_home_screen.dart';
import 'guardian_settings_screen.dart'; // ✅ 추가

class GuardianAnalysisScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const GuardianAnalysisScreen({
    super.key,
    this.onOpenSettings,
  });

  @override
  State<GuardianAnalysisScreen> createState() => _GuardianAnalysisScreenState();
}

class _GuardianAnalysisScreenState extends State<GuardianAnalysisScreen> {
  String elderlyName = '어머니';
  int _selectedIndex = 1; // 상세 분석이 선택된 상태

  // 요일별 데이터
  final Map<String, EmotionCount> weekdayData = {
    '월': EmotionCount(positive: 2, negative: 2),
    '화': EmotionCount(positive: 3, negative: 1),
    '수': EmotionCount(positive: 4, negative: 0),
    '목': EmotionCount(positive: 3, negative: 1),
    '금': EmotionCount(positive: 2, negative: 2),
    '토': EmotionCount(positive: 4, negative: 0),
    '일': EmotionCount(positive: 3, negative: 1),
  };

  // 시간대별 데이터
  final Map<String, EmotionCount> timeData = {
    '오전': EmotionCount(positive: 5, negative: 5),
    '오후': EmotionCount(positive: 8, negative: 2),
    '저녁': EmotionCount(positive: 8, negative: 2),
  };

  // 전체 감정 비율
  final EmotionRatio emotionRatio = EmotionRatio(
    positive: 18,
    normal: 7,
    negative: 3,
    serious: 2,
  );

  // 주제별 데이터
  final List<TopicData> topics = [
    TopicData(name: '가족', count: 45, color: Color(0xFF66BB6A)),
    TopicData(name: '건강', count: 38, color: Color(0xFFFFB74D)),
    TopicData(name: '취미', count: 25, color: Color(0xFF64B5F6)),
    TopicData(name: '외로움', count: 18, color: Color(0xFFEF5350)),
    TopicData(name: '금전', count: 12, color: Color(0xFF9575CD)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '상세 분석',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$elderlyName님의 감정 패턴',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '최근 30일 데이터 기반',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 1. 요일별 감정 패턴
                    _buildWeekdayPattern(),
                    const SizedBox(height: 32),

                    // 2. 시간대별 패턴
                    _buildTimePattern(),
                    const SizedBox(height: 32),

                    // 3. 감정 비율 파이차트
                    _buildEmotionRatio(),
                    const SizedBox(height: 32),

                    // 4. 주제 분석
                    _buildTopicAnalysis(),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(), // ✅ 하단 네비게이션
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayPattern() {
    // 월요일에 부정 감정이 많은지 확인
    final mondayNegative = weekdayData['월']!.negative;
    final avgNegative = weekdayData.values
            .map((e) => e.negative)
            .reduce((a, b) => a + b) /
        weekdayData.length;

    String comment = '';
    if (mondayNegative > avgNegative * 1.5) {
      comment = '💡 월요일에 유난히 부정 감정이 많아요';
    } else if (weekdayData['토']!.positive > avgNegative * 1.5) {
      comment = '💡 주말에 기분이 좋으신 편이에요';
    } else {
      comment = '💡 요일별로 고른 감정 패턴을 보이고 있어요';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF66BB6A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '요일별 감정 패턴',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekdayData.entries.map((entry) {
                final maxCount = 4;
                final positiveHeight =
                    (entry.value.positive / maxCount) * 150;
                final negativeHeight =
                    (entry.value.negative / maxCount) * 150;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 긍정 막대
                    Container(
                      width: 30,
                      height: positiveHeight,
                      decoration: const BoxDecoration(
                        color: Color(0xFF66BB6A),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 부정 막대
                    Container(
                      width: 30,
                      height: negativeHeight,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF5350),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallLegend('긍정', const Color(0xFF66BB6A)),
              const SizedBox(width: 20),
              _buildSmallLegend('부정', const Color(0xFFEF5350)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFFB74D),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    comment,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePattern() {
    // 시간대별 분석
    final morningNegative = timeData['오전']!.negative;
    final afternoonNegative = timeData['오후']!.negative;
    final eveningNegative = timeData['저녁']!.negative;

    String comment = '';
    if (morningNegative >= afternoonNegative &&
        morningNegative >= eveningNegative) {
      comment = '💡 아침에 기분이 안 좋은 편이에요';
    } else if (eveningNegative >= morningNegative &&
        eveningNegative >= afternoonNegative) {
      comment = '💡 저녁에 외로움을 많이 느끼시는 것 같아요';
    } else {
      comment = '💡 오후에 가장 안정적인 감정을 보이세요';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFFFFB74D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '시간대별 패턴',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...timeData.entries.map((entry) {
            final total = entry.value.positive + entry.value.negative;
            final positiveRatio = entry.value.positive / total;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      Text(
                        '${(positiveRatio * 100).toInt()}% 긍정',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 40,
                          color: const Color(0xFFEF5350).withOpacity(0.3),
                        ),
                        FractionallySizedBox(
                          widthFactor: positiveRatio,
                          child: Container(
                            height: 40,
                            color: const Color(0xFF66BB6A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFFB74D),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    comment,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionRatio() {
    final total = emotionRatio.positive +
        emotionRatio.normal +
        emotionRatio.negative +
        emotionRatio.serious;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B5F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Color(0xFF64B5F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '전체 감정 비율',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CustomPaint(
                        painter: PieChartPainter(
                          positive: emotionRatio.positive / total,
                          normal: emotionRatio.normal / total,
                          negative: emotionRatio.negative / total,
                          serious: emotionRatio.serious / total,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRatioItem(
                      '긍정',
                      emotionRatio.positive,
                      total,
                      const Color(0xFF66BB6A),
                    ),
                    const SizedBox(height: 12),
                    _buildRatioItem(
                      '보통',
                      emotionRatio.normal,
                      total,
                      const Color(0xFFFFB74D),
                    ),
                    const SizedBox(height: 12),
                    _buildRatioItem(
                      '부정',
                      emotionRatio.negative,
                      total,
                      const Color(0xFF64B5F6),
                    ),
                    const SizedBox(height: 12),
                    _buildRatioItem(
                      '심각',
                      emotionRatio.serious,
                      total,
                      const Color(0xFFEF5350),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicAnalysis() {
    final maxCount =
        topics.map((t) => t.count).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9575CD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.topic,
                  color: Color(0xFF9575CD),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '대화 주제 분석',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '자주 언급되는 주제예요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ...topics.map((topic) {
            final ratio = topic.count / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        topic.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      Text(
                        '${topic.count}회',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          color: Colors.grey[200],
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 12,
                            color: topic.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRatioItem(String label, int count, int total, Color color) {
    final percentage = (count / total * 100).toInt();
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 15,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ✅ 하단 네비게이션 바
  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 홈
          _buildNavItem(
            icon: Icons.home,
            label: '홈',
            isSelected: _selectedIndex == 0,
            onTap: () {
              if (_selectedIndex == 0) return;
              setState(() => _selectedIndex = 0);
              Navigator.pop(context); // 홈으로 돌아가기
            },
          ),
          // 상세 분석 (현재 화면)
          _buildNavItem(
            icon: Icons.insert_chart,
            label: '상세 분석',
            isSelected: _selectedIndex == 1,
            onTap: () {
              // 현재 화면이라 아무 동작 X
            },
          ),
          // 설정 → ✅ 보호자 설정 화면으로 이동
          _buildNavItem(
            icon: Icons.settings,
            label: '설정',
            isSelected: _selectedIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuardianSettingsScreen(
                    onBack: () => Navigator.pop(context),
                    onLogout: () {
                      // 여기서는 상위의 실제 로그아웃 콜백이 없어서
                      // 나중에 필요하면 GuardianAnalysisScreen에 onLogout도 받아서 넘겨주면 돼!
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8D6E63),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 파이차트 페인터
class PieChartPainter extends CustomPainter {
  final double positive;
  final double normal;
  final double negative;
  final double serious;

  PieChartPainter({
    required this.positive,
    required this.normal,
    required this.negative,
    required this.serious,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -90 * 3.14159 / 180;

    // 긍정
    final positivePaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;
    final positiveAngle = positive * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      positiveAngle,
      true,
      positivePaint,
    );
    startAngle += positiveAngle;

    // 보통
    final normalPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.fill;
    final normalAngle = normal * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      normalAngle,
      true,
      normalPaint,
    );
    startAngle += normalAngle;

    // 부정
    final negativePaint = Paint()
      ..color = const Color(0xFF64B5F6)
      ..style = PaintingStyle.fill;
    final negativeAngle = negative * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      negativeAngle,
      true,
      negativePaint,
    );
    startAngle += negativeAngle;

    // 심각
    final seriousPaint = Paint()
      ..color = const Color(0xFFEF5350)
      ..style = PaintingStyle.fill;
    final seriousAngle = serious * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      seriousAngle,
      true,
      seriousPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 데이터 모델
class EmotionCount {
  final int positive;
  final int negative;

  EmotionCount({required this.positive, required this.negative});
}

class EmotionRatio {
  final int positive;
  final int normal;
  final int negative;
  final int serious;

  EmotionRatio({
    required this.positive,
    required this.normal,
    required this.negative,
    required this.serious,
  });
}

class TopicData {
  final String name;
  final int count;
  final Color color;

  TopicData({
    required this.name,
    required this.count,
    required this.color,
  });
}
