import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'call_history_screen.dart';
import 'settings_screen.dart';
import '../screens/video_call_screen.dart';
import '../maldong_avatar.dart';

const String baseUrl = 'http://127.0.0.1:8000';
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
  String? todayTopEmotion; // ✅ 오늘 가장 많이 나온 감정
  String userName = '사용자';

  int _selectedIndex = 0;
  bool _isLoading = true;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  int? _userId;
  String? _accessToken;

  // ✅ 이번 달 감정 통계
  Map<String, EmotionData> monthlyData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // =========================================================
  // 🔹 사용자 + 오늘 감정 + 월별 통계 로드
  // =========================================================
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('access_token');
      final username = prefs.getString('username');

      if (userId == null || token == null) {
        throw Exception('로그인 정보 없음');
      }

      setState(() {
        _userId = userId;
        _accessToken = token;
        userName = username ?? '사용자';
      });

      await Future.wait([
        _loadTodayTopEmotion(userId, token),
        _loadMonthlyStats(userId, token, selectedYear, selectedMonth),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      print('홈 데이터 로드 오류: $e');
      setState(() => _isLoading = false);
    }
  }

  // =========================================================
  // 🔹 오늘 가장 많이 나온 감정 (배너용)
  // =========================================================
  Future<void> _loadTodayTopEmotion(int userId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/emotions/$userId/today-top');

      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          todayTopEmotion = data['emotion'];
        });
      } else {
        todayTopEmotion = null;
      }
    } catch (e) {
      print('오늘 감정 로드 오류: $e');
      todayTopEmotion = null;
    }
  }

  // =========================================================
  // 🔹 이번 달 감정 통계
  // =========================================================
  Future<void> _loadMonthlyStats(int userId, String token, int year, int month) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/v1/emotions/$userId/monthly-stats?year=$year&month=$month',
      );

      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          monthlyData['$year-$month'] = EmotionData(
            joy: d['joy'] ?? 0,
            anger: d['anger'] ?? 0,
            anxiety: d['anxiety'] ?? 0,
            sadness: d['sadness'] ?? 0,
          );
        });
      }
    } catch (e) {
      print('월별 통계 오류: $e');
    }
  }

  // =========================================================
  // 🔹 UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final monthKey = '$selectedYear-$selectedMonth';
    final currentData =
        monthlyData[monthKey] ?? EmotionData(joy: 0, anger: 0, anxiety: 0, sadness: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTodayEmotionBanner(),
                    const SizedBox(height: 32),
                    _buildChatButton(),
                    const SizedBox(height: 40),
                    _buildEmotionRecordSection(currentData),
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

  // =========================================================
  // 🔹 배너: 오늘 최다 감정
  // =========================================================
  Widget _buildTodayEmotionBanner() {
    if (todayTopEmotion == null) {
      return _emptyBanner();
    }

    final color = _getEmotionColor(todayTopEmotion!);
    final icon = _getEmotionIcon(todayTopEmotion!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$userName님의 오늘',
                    style: const TextStyle(fontSize: 14, color: Colors.brown)),
                const SizedBox(height: 4),
                Text(
                  '가장 많이 나온 감정은 "$todayTopEmotion"',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: const Text(
        '말동이와 대화하면 오늘의 감정이 기록돼요 🌱',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  // =========================================================
  // 🔹 이번 달 통계
  // =========================================================
  Widget _buildEmotionRecordSection(EmotionData data) {
    final total = data.total;

    if (total == 0) {
      return const Text('이번 달 감정 기록이 없어요');
    }

    return Column(
      children: [
        _buildEmotionCard('기쁨', data.joy, total),
        _buildEmotionCard('분노', data.anger, total),
        _buildEmotionCard('불안', data.anxiety, total),
        _buildEmotionCard('슬픔', data.sadness, total),
      ],
    );
  }

  Widget _buildEmotionCard(String label, int count, int total) {
    final percent = total == 0 ? 0 : (count / total * 100).toInt();
    return ListTile(
      title: Text(label),
      trailing: Text('$count회 ($percent%)'),
    );
  }

  // =========================================================
  // 🔹 기타
  // =========================================================
  Widget _buildChatButton() {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              userId: _userId!,
              accessToken: _accessToken!,
              avatar: MaldongAvatar(url: customAvatarUrl),
              onEndCall: () {},
            ),
          ),
        );
        _loadUserData(); // ✅ 통화 후 갱신
      },
      child: const Text('말동이와 영상통화'),
    );
  }

  Widget _buildBottomNavigation() => const SizedBox(height: 60);

  IconData _getEmotionIcon(String e) {
    switch (e) {
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

  Color _getEmotionColor(String e) {
    switch (e) {
      case '기쁨':
        return Colors.green;
      case '분노':
        return Colors.red;
      case '불안':
        return Colors.blue;
      case '슬픔':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// =========================================================
class EmotionData {
  final int joy, anger, anxiety, sadness;
  EmotionData({
    required this.joy,
    required this.anger,
    required this.anxiety,
    required this.sadness,
  });
  int get total => joy + anger + anxiety + sadness;
}
