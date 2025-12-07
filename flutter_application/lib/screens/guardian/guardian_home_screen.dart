import 'package:flutter/material.dart';
import 'guardian_analysis_screen.dart';
import 'guardian_settings_screen.dart';

class GuardianHomeScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;

  const GuardianHomeScreen({
    super.key,
    required this.onOpenSettings,
    required this.onLogout,
  });

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  String elderlyName = '어머니';
  int _selectedIndex = 0;
<<<<<<< HEAD

  // 샘플 데이터 (최근 30일)
  final List<DailyEmotion> recentEmotions = [
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 0)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 1)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 2)), emotion: '보통'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 3)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 4)), emotion: '부정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 5)), emotion: '보통'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 6)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 7)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 8)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 9)), emotion: '보통'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 10)), emotion: '부정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 11)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 12)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 13)), emotion: '보통'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 14)), emotion: '심각'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 15)), emotion: '부정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 16)), emotion: '보통'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 17)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 18)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 19)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 20)), emotion: '보통'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 21)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 22)), emotion: '부정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 23)), emotion: '보통'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 24)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 25)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 26)), emotion: '보통'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 27)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 28)), emotion: '긍정'),
    DailyEmotion(date: DateTime.now().subtract(const Duration(days: 29)), emotion: '심각'),
  ];

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final todayEmotion = recentEmotions.first;
=======
  bool isLoading = true;
  String? errorMessage;
  
  static const String baseUrl = 'http://localhost:8000';
  
  List<DailyEmotion> recentEmotions = [];
  EmotionStats? emotionStats;

  @override
  void initState() {
    super.initState();
    _loadGuardianData();
  }

  Future<void> _loadGuardianData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      await _getWardInfo();
      await _getWardEmotions();
      await _getEmotionStats();
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '데이터 로딩 실패: $e';
      });
      print('데이터 로딩 실패: $e');
    }
  }

  Future<void> _getWardInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/guardian/ward-info/${widget.guardianUserId}'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          elderlyName = data['username'];
        });
      } else if (response.statusCode == 404) {
        throw Exception('연동된 어르신을 찾을 수 없습니다');
      } else {
        throw Exception('어르신 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _getWardEmotions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/guardian/ward-emotions/${widget.guardianUserId}?days=30'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          recentEmotions = data.map((item) => DailyEmotion.fromJson(item)).toList();
        });
      } else {
        throw Exception('감정 데이터 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _getEmotionStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/guardian/emotion-stats/${widget.guardianUserId}?days=30'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          emotionStats = EmotionStats.fromJson(data);
        });
      } else {
        throw Exception('통계 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
              ),
              const SizedBox(height: 16),
              Text(
                '데이터를 불러오는 중...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadGuardianData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66BB6A),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = emotionStats ?? EmotionStats(joy: 0, anger: 0, anxiety: 0, sadness: 0);
    final todayEmotion = recentEmotions.isNotEmpty 
        ? recentEmotions.first 
        : DailyEmotion(
            date: DateTime.now(),
            emotionName: '불안',
            riskScore: 0.0,
          );
>>>>>>> develop

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
<<<<<<< HEAD
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // 오늘의 감정
                          _buildTodayEmotionCard(todayEmotion),
                          const SizedBox(height: 24),

                          // 30일 감정 추이
                          _buildEmotionTrendCard(),
                          const SizedBox(height: 24),

                          // 통계 요약
                          _buildStatsCards(stats),
                          const SizedBox(height: 24),

                          // 빠른 메뉴
                          _buildQuickMenu(),
                        ],
=======
              child: RefreshIndicator(
                onRefresh: _loadGuardianData,
                color: const Color(0xFF66BB6A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _buildTodayEmotionCard(todayEmotion),
                            const SizedBox(height: 24),
                            _buildEmotionTrendCard(),
                            const SizedBox(height: 24),
                            _buildStatsCards(stats),
                            const SizedBox(height: 24),
                            _buildQuickMenu(),
                          ],
                        ),
>>>>>>> develop
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.family_restroom,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '보호자 대시보드',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8D6E63),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$elderlyName님의 상태',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayEmotionCard(DailyEmotion todayEmotion) {
<<<<<<< HEAD
    final color = _getEmotionColor(todayEmotion.emotion);
    final emoji = _getEmotionEmoji(todayEmotion.emotion);
=======
    final color = _getEmotionColor(todayEmotion.emotionName);
    final emoji = _getEmotionEmoji(todayEmotion.emotionName);
>>>>>>> develop

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
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
            '오늘의 기분',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            todayEmotion.emotion,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionTrendCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            '최근 30일 감정 추이',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 16),
<<<<<<< HEAD
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentEmotions.length,
              reverse: true,
              itemBuilder: (context, index) {
                final emotion = recentEmotions[index];
                final color = _getEmotionColor(emotion.emotion);
                final day = emotion.date.day;
=======
          recentEmotions.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Text(
                    '감정 데이터가 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentEmotions.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final emotion = recentEmotions[index];
                      final color = _getEmotionColor(emotion.emotionName);
                      final day = emotion.date.day;
>>>>>>> develop

                return Container(
                  width: 32,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          width: 32,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegend('기쁨', const Color(0xFF66BB6A)),
              _buildLegend('분노', const Color(0xFFEF5350)),
              _buildLegend('불안', const Color(0xFF64B5F6)),
              _buildLegend('슬픔', const Color(0xFF9575CD)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(EmotionStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '기쁨',
                stats.joy,
                const Color(0xFF66BB6A),
                '😊',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '분노',
                stats.anger,
                const Color(0xFFEF5350),
                '😡',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '불안',
                stats.anxiety,
                const Color(0xFF64B5F6),
                '😟',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '슬픔',
                stats.sadness,
                const Color(0xFF9575CD),
                '😢',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, String emoji) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count일',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 메뉴',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuButton(
          icon: Icons.history,
          title: '통화 기록 보기',
          color: const Color(0xFF66BB6A),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('통화 기록 화면')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          icon: Icons.notifications_active,
          title: '알림 설정',
          color: const Color(0xFFFFB74D),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 설정 화면')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          icon: Icons.contact_phone,
          title: '긴급 연락',
          color: const Color(0xFFEF5350),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('긴급 연락 기능')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

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
          _buildNavItem(
            icon: Icons.home,
            label: '홈',
            isSelected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
            },
          ),
          _buildNavItem(
            icon: Icons.insert_chart,
            label: '상세 분석',
            isSelected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuardianAnalysisScreen(
<<<<<<< HEAD
=======
                    guardianUserId: widget.guardianUserId,
                    accessToken: widget.accessToken,
>>>>>>> develop
                    onOpenSettings: widget.onOpenSettings,
                  ),
                ),
              );
            },
          ),
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
<<<<<<< HEAD
=======
                    guardianUserId: widget.guardianUserId,
                    accessToken: widget.accessToken,
>>>>>>> develop
                    onBack: () => Navigator.pop(context),
                    onLogout: widget.onLogout,
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

  Widget _buildLegend(String label, Color color) {
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

<<<<<<< HEAD
  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case '긍정':
=======
  Color _getEmotionColor(String emotionName) {
    switch (emotionName) {
      case '기쁨':
>>>>>>> develop
        return const Color(0xFF66BB6A);
      case '분노':
        return const Color(0xFFEF5350);
      case '불안':
        return const Color(0xFF64B5F6);
      case '슬픔':
        return const Color(0xFF9575CD);
      default:
        return Colors.grey;
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion) {
      case '긍정':
        return '😊';
<<<<<<< HEAD
      case '보통':
        return '😐';
      case '부정':
        return '😕';
      case '심각':
=======
      case '분노':
        return '😡';
      case '불안':
        return '😟';
      case '슬픔':
>>>>>>> develop
        return '😢';
      default:
        return '😐';
    }
  }

  EmotionStats _calculateStats() {
    int positive = 0;
    int normal = 0;
    int negative = 0;
    int serious = 0;

    for (var emotion in recentEmotions) {
      switch (emotion.emotion) {
        case '긍정':
          positive++;
          break;
        case '보통':
          normal++;
          break;
        case '부정':
          negative++;
          break;
        case '심각':
          serious++;
          break;
      }
    }

    return EmotionStats(
      positive: positive,
      normal: normal,
      negative: negative,
      serious: serious,
    );
  }
}

class DailyEmotion {
  final DateTime date;
<<<<<<< HEAD
  final String emotion;

  DailyEmotion({required this.date, required this.emotion});
=======
  final String emotionName;  // "기쁨", "분노", "불안", "슬픔"
  final double riskScore;

  DailyEmotion({
    required this.date,
    required this.emotionName,
    required this.riskScore,
  });

  factory DailyEmotion.fromJson(Map<String, dynamic> json) {
    return DailyEmotion(
      date: DateTime.parse(json['date']),
      emotionName: json['emotion_name'] ?? '불안',
      riskScore: (json['avg_risk_score'] ?? 0.0).toDouble(),
    );
  }
>>>>>>> develop
}

class EmotionStats {
  final int joy;      // 기쁨
  final int anger;    // 분노
  final int anxiety;  // 불안
  final int sadness;  // 슬픔

  EmotionStats({
    required this.joy,
    required this.anger,
    required this.anxiety,
    required this.sadness,
  });
<<<<<<< HEAD
}
=======

  factory EmotionStats.fromJson(Map<String, dynamic> json) {
    return EmotionStats(
      joy: json['joy'] ?? 0,
      anger: json['anger'] ?? 0,
      anxiety: json['anxiety'] ?? 0,
      sadness: json['sadness'] ?? 0,
    );
  }
}
>>>>>>> develop
