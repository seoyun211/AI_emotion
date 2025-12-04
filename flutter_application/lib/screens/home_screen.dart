import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'call_history_screen.dart';
import 'settings_screen.dart';
import '../screens/video_call_screen.dart';
import '../maldong_avatar.dart';

const String baseUrl = 'http://localhost:8000';
const customAvatarUrl = 'assets/model.glb';

class HomeScreen extends StatefulWidget {
  final VoidCallback onStartCall;
  final Widget avatar;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.onStartCall,
    required this.avatar,
    required this.onOpenSettings,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentEmotion = '기쁨';
  String emotionLevel = '긍정';
  String userName = '사용자';
  int _selectedIndex = 0;
  bool _isLoading = true;
  int selectedMonth = DateTime.now().month;
  
  // ✅ 로그인 정보 저장
  int? _userId;
  String? _accessToken;
  
  // 월별 감정 데이터
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
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 정보와 오늘의 감정 데이터 로드
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('access_token');
      final username = prefs.getString('username');

      if (userId == null || token == null) {
        throw Exception('로그인 정보가 없습니다');
      }

      // ✅ 로그인 정보 저장
      setState(() {
        _userId = userId;
        _accessToken = token;
        userName = username ?? '사용자';
      });

      // 2. 최근 감정 목록 가져오기 (limit=1로 가장 최근 것만)
      final emotionUrl = Uri.parse('$baseUrl/api/v1/emotions/$userId/list?limit=1');
      final emotionResponse = await http.get(
        emotionUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (emotionResponse.statusCode == 200) {
        final data = jsonDecode(emotionResponse.body);
        final emotions = data['emotions'] as List;
        
        if (emotions.isNotEmpty) {
          final latestEmotion = emotions[0];
          
          setState(() {
            currentEmotion = latestEmotion['emotion'] ?? '기쁨';
            emotionLevel = _getEmotionLevelFromEmotion(currentEmotion);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 감정 이름으로 감정 레벨 추론
  String _getEmotionLevelFromEmotion(String emotion) {
    // 감정 매핑: 기쁨:0 당황:1 분노:2 불안:3 상처:4 슬픔:5 중립:6 역겨움:7 공포:8 놀람:9
    
    if (emotion == '기쁨' || emotion == '놀람') {
      return '긍정';
    } else if (emotion == '중립' || emotion == '당황') {
      return '보통';
    } else if (emotion == '불안' || emotion == '상처' || emotion == '슬픔') {
      return '부정';
    } else if (emotion == '분노' || emotion == '역겨움' || emotion == '공포') {
      return '심각';
    } else {
      return '보통';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF9800),
          ),
        ),
      );
    }

    final currentData = monthlyData[selectedMonth]!;
    final total = currentData.total;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildEmotionBanner(),
                    const SizedBox(height: 40),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // 말동이와 영상통화 버튼
                          _buildChatButton(),
                          const SizedBox(height: 40),

                          // 감정 기록 섹션
                          _buildEmotionRecordSection(currentData, total),
                        ],
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

  Widget _buildEmotionBanner() {
    Color emotionColor = _getEmotionColor();
    String comment = _getEmotionComment();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: emotionColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEmotionIcon(),
                  size: 32,
                  color: emotionColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName님의 오늘',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8D6E63),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '기분은 ',
                          style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            currentEmotion,
                            style: TextStyle(
                              fontSize: 28,
                              color: emotionColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: emotionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              comment,
              style: TextStyle(
                fontSize: 15,
                color: emotionColor.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              onEndCall: () {
                Navigator.pop(context);
                _loadUserData();
              },
              avatar: MaldongAvatar(url: customAvatarUrl),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFB74D),
              Color(0xFFFF9800),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: const [
            Icon(
              Icons.videocam,
              size: 56,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              '말동이와 영상통화',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionRecordSection(EmotionData currentData, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이번 달 감정 기록',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        const SizedBox(height: 16),

        // 월 선택
        _buildMonthSelector(),
        const SizedBox(height: 24),

        // 가장 많은 감정
        _buildTopEmotion(currentData),
        const SizedBox(height: 24),

        // 감정 카드들
        _buildEmotionCard('긍정', currentData.positive, total, 
          const Color(0xFF66BB6A), '😊'),
        const SizedBox(height: 12),
        _buildEmotionCard('보통', currentData.normal, total, 
          const Color(0xFFFFB74D), '😐'),
        const SizedBox(height: 12),
        _buildEmotionCard('부정', currentData.negative, total, 
          const Color(0xFF64B5F6), '😕'),
        const SizedBox(height: 12),
        _buildEmotionCard('심각', currentData.serious, total, 
          const Color(0xFFEF5350), '😢'),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            icon: const Icon(Icons.chevron_left, color: Color(0xFF5D4037), size: 28),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$selectedMonth월',
                style: const TextStyle(
                  fontSize: 24,
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
            icon: const Icon(Icons.chevron_right, color: Color(0xFF5D4037), size: 28),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topColor, topColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
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
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            '이번 달 가장 많은 기분',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            topEmotion,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '$topCount번',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionCard(String label, int count, int total, Color color, String emoji) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$count번',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($percentage%)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
            icon: Icons.history,
            label: '통화기록',
            isSelected: _selectedIndex == 1,
            onTap: () {
              // ✅ userId와 accessToken이 있을 때만 이동
              if (_userId != null && _accessToken != null) {
                setState(() => _selectedIndex = 1);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallHistoryScreen(
                      userId: _userId!,
                      accessToken: _accessToken!,
                    ),
                  ),
                ).then((_) {
                  // 돌아왔을 때 홈 탭으로 리셋
                  setState(() => _selectedIndex = 0);
                });
              } else {
                // 로그인 정보가 없는 경우
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('로그인 정보를 불러오는 중입니다...'),
                    backgroundColor: Color(0xFFFF9800),
                  ),
                );
              }
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
                  builder: (context) => SettingsScreen(
                    onBack: () => Navigator.pop(context),
                    onLogout: () => Navigator.pop(context),
                  ),
                ),
              ).then((_) {
                // 돌아왔을 때 홈 탭으로 리셋
                setState(() => _selectedIndex = 0);
              });
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
            color: isSelected ? const Color(0xFFFF9800) : Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? const Color(0xFFFF9800) : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmotionIcon() {
    switch (emotionLevel) {
      case '긍정':
        return Icons.sentiment_very_satisfied;
      case '보통':
        return Icons.sentiment_satisfied;
      case '부정':
        return Icons.sentiment_dissatisfied;
      case '심각':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getEmotionColor() {
    switch (emotionLevel) {
      case '긍정':
        return const Color(0xFF66BB6A);
      case '보통':
        return const Color(0xFFFFB74D);
      case '부정':
        return const Color(0xFF64B5F6);
      case '심각':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  String _getEmotionComment() {
    switch (emotionLevel) {
      case '긍정':
        return '오늘은 표정이 밝아 보여요 😊';
      case '보통':
        return '평온한 하루를 보내고 계시네요';
      case '부정':
        return '조금 힘든 하루인가요? 말동이가 함께할게요';
      case '심각':
        return '많이 힘드시죠? 언제든 이야기 나눠요';
      default:
        return '오늘 하루는 어떠셨나요?';
    }
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