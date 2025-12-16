import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'call_history_screen.dart';
import 'settings_screen.dart';
import '../screens/video_call_screen.dart';
import '../maldong_avatar.dart';

//const String baseUrl = 'http://10.0.2.2:8000';
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
  String? currentEmotion; // null이면 오늘 감정 기록 없음
  String userName = '사용자';
  int _selectedIndex = 0;
  bool _isLoading = true;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  
  // 로그인 정보 저장
  int? _userId;
  String? _accessToken;
  
  // 월별 감정 데이터 (DB에서 가져옴)
  Map<String, EmotionData> monthlyData = {};

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

      setState(() {
        _userId = userId;
        _accessToken = token;
        userName = username ?? '사용자';
      });

      // 최근 감정과 월별 통계를 병렬로 로드
      await Future.wait([
        _loadLatestEmotion(userId, token),
        _loadMonthlyStats(userId, token, selectedYear, selectedMonth),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 최근 감정 로드
  Future<void> _loadLatestEmotion(int userId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/emotions/$userId/latest');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // emotion이 null이거나 비어있으면 오늘 감정 기록 없음
        if (data['emotion'] != null && data['emotion'].toString().isNotEmpty) {
          setState(() {
            currentEmotion = data['emotion'];
          });
        } else {
          setState(() {
            currentEmotion = null; // 감정 기록 없음
          });
        }
      } else {
        setState(() {
          currentEmotion = null;
        });
      }
    } catch (e) {
      print('최근 감정 로드 오류: $e');
      setState(() {
        currentEmotion = null;
      });
    }
  }

  // 월별 감정 통계 로드
  Future<void> _loadMonthlyStats(int userId, String token, int year, int month) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/v1/emotions/$userId/monthly-stats?year=$year&month=$month'
      );
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final emotionData = EmotionData(
          joy: data['joy'] ?? 0,
          anger: data['anger'] ?? 0,
          anxiety: data['anxiety'] ?? 0,
          sadness: data['sadness'] ?? 0,
        );

        setState(() {
          monthlyData['$year-$month'] = emotionData;
        });
      }
    } catch (e) {
      print('월별 통계 로드 오류: $e');
      // 오류 발생 시 빈 데이터로 초기화
      setState(() {
        monthlyData['$year-$month'] = EmotionData(
          joy: 0,
          anger: 0,
          anxiety: 0,
          sadness: 0,
        );
      });
    }
  }

  // 월 변경 시 데이터 다시 로드
  Future<void> _onMonthChanged(int newMonth) async {
    setState(() {
      selectedMonth = newMonth;
      _isLoading = true;
    });

    if (_userId != null && _accessToken != null) {
      await _loadMonthlyStats(_userId!, _accessToken!, selectedYear, selectedMonth);
    }

    setState(() {
      _isLoading = false;
    });
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

    final currentData = monthlyData['$selectedYear-$selectedMonth'] ?? 
      EmotionData(joy: 0, anger: 0, anxiety: 0, sadness: 0);
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
                          _buildChatButton(),
                          const SizedBox(height: 40),
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
    // 오늘 감정 기록이 없는 경우
    if (currentEmotion == null) {
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
                    color: const Color(0xFFFFB74D).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    size: 32,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$userName님, 안녕하세요!',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8D6E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '오늘은 어떤 하루인가요?',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF5D4037),
                          fontWeight: FontWeight.w600,
                        ),
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
                color: const Color(0xFFFFB74D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '말동이와 대화하며 오늘의 기분을 기록해보세요 🌟',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 감정 기록이 있는 경우 (기존 코드)
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
                            currentEmotion!,
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
        if (_userId != null && _accessToken != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallScreen(
                onEndCall: () {
                  Navigator.pop(context);
                  _loadUserData();
                },
                avatar: MaldongAvatar(url: customAvatarUrl),
                userId: _userId!,
                accessToken: _accessToken!,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인 정보를 불러오는 중입니다...'),
              backgroundColor: Color(0xFFFF9800),
            ),
          );
        }
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

        _buildMonthSelector(),
        const SizedBox(height: 24),

        // 데이터가 없을 경우 메시지 표시
        if (total == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
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
            child: Column(
              children: const [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Color(0xFFBDBDBD),
                ),
                SizedBox(height: 16),
                Text(
                  '이번 달 감정 기록이 없어요',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '말동이와 대화를 시작해보세요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          )
        else ...[
          _buildTopEmotion(currentData),
          const SizedBox(height: 24),
          _buildEmotionCard('기쁨', currentData.joy, total, 
            const Color(0xFF66BB6A), '😊'),
          const SizedBox(height: 12),
          _buildEmotionCard('분노', currentData.anger, total, 
            const Color(0xFFEF5350), '😡'),
          const SizedBox(height: 12),
          _buildEmotionCard('불안', currentData.anxiety, total, 
            const Color(0xFF64B5F6), '😟'),
          const SizedBox(height: 12),
          _buildEmotionCard('슬픔', currentData.sadness, total, 
            const Color(0xFF9575CD), '😢'),
        ],
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
              int newMonth = selectedMonth > 1 ? selectedMonth - 1 : 12;
              _onMonthChanged(newMonth);
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
              int newMonth = selectedMonth < 12 ? selectedMonth + 1 : 1;
              _onMonthChanged(newMonth);
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

    // 4개 감정 중 가장 많은 것 찾기
    final emotions = [
      {'name': '기쁨', 'count': data.joy, 'color': const Color(0xFF66BB6A), 'emoji': '😊'},
      {'name': '분노', 'count': data.anger, 'color': const Color(0xFFEF5350), 'emoji': '😡'},
      {'name': '불안', 'count': data.anxiety, 'color': const Color(0xFF64B5F6), 'emoji': '😟'},
      {'name': '슬픔', 'count': data.sadness, 'color': const Color(0xFF9575CD), 'emoji': '😢'},
    ];

    emotions.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    final top = emotions.first;
    topEmotion = top['name'] as String;
    topCount = top['count'] as int;
    topColor = top['color'] as Color;
    emoji = top['emoji'] as String;

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
                  setState(() => _selectedIndex = 0);
                });
              } else {
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
    if (currentEmotion == null) return Icons.waving_hand;
    
    switch (currentEmotion) {
      case '기쁨':
        return Icons.sentiment_very_satisfied;
      case '분노':
        return Icons.sentiment_very_dissatisfied;
      case '불안':
        return Icons.sentiment_dissatisfied;
      case '슬픔':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getEmotionColor() {
    if (currentEmotion == null) return const Color(0xFFFF9800);
    
    switch (currentEmotion) {
      case '기쁨':
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

  String _getEmotionComment() {
    if (currentEmotion == null) {
      return '말동이와 대화하며 오늘의 기분을 기록해보세요 🌟';
    }
    
    switch (currentEmotion) {
      case '기쁨':
        return '오늘은 표정이 밝아 보여요 😊';
      case '분노':
        return '화가 나는 일이 있으셨나요? 말동이가 들어드릴게요';
      case '불안':
        return '조금 불안하신가요? 말동이와 함께 이야기해요';
      case '슬픔':
        return '많이 힘드시죠? 언제든 이야기 나눠요';
      default:
        return '오늘 하루는 어떠셨나요?';
    }
  }
}

class EmotionData {
  final int joy;
  final int anger;
  final int anxiety;
  final int sadness;

  EmotionData({
    required this.joy,
    required this.anger,
    required this.anxiety,
    required this.sadness,
  });

  int get total => joy + anger + anxiety + sadness;
}