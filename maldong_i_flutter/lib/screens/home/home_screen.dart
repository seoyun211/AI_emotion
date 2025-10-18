// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../api/emotion_api.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onScreenChange;
  final Function(bool) onCallStatusChange;

  const HomeScreen({
    super.key,
    required this.onScreenChange,
    required this.onCallStatusChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool serverOnline = false;

  @override
  void initState() {
    super.initState();
    checkServerStatus();
  }

  Future<void> checkServerStatus() async {
    try {
      final isOnline = await EmotionApi.checkServerHealth();
      setState(() {
        serverOnline = isOnline;
      });
    } catch (error) {
      print('서버 상태 확인 실패: $error');
      setState(() {
        serverOnline = false;
      });
    }
  }

  void handleStartCall() {
    if (serverOnline) {
      print('영상통화 시작 - 백엔드에 알림');
    }
    widget.onCallStatusChange(true);
    widget.onScreenChange('call');
  }

  void handleViewHistory() {
    if (serverOnline) {
      print('기록 조회 - 백엔드 데이터 로드');
    }
    widget.onScreenChange('history');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Column(
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      '말동이',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '언제든 이야기하세요',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: serverOnline ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        serverOnline ? Icons.check_circle : Icons.error,
                        color: serverOnline ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        serverOnline ? '✅ 서버 연결됨' : '❌ 서버 연결 안됨',
                        style: TextStyle(
                          fontSize: 14,
                          color: serverOnline ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildActionButton(
                  title: '영상통화 시작',
                  icon: Icons.call,
                  color: Colors.green,
                  onPressed: handleStartCall,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  title: '감정 기록 보기',
                  icon: Icons.favorite,
                  color: Colors.blue,
                  onPressed: handleViewHistory,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}