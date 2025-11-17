import 'package:flutter/material.dart';
import 'call_history_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onStartCall;

  const HomeScreen({
    super.key,
    required this.onOpenSettings,
    required this.onStartCall,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 현재 감정 상태 (테스트용)
  String currentEmotion = '기쁨';
  String emotionLevel = '긍정'; // 긍정, 보통, 부정, 심각
  String userName = '사용자';
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 감정 상태 배너
                    _buildEmotionBanner(),
                    
                    const SizedBox(height: 40),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // 중앙 대화 버튼
                          _buildChatButton(),
                          
                          const SizedBox(height: 32),
                          
                          // 기능 카드들
                          Row(
                            children: [
                              Expanded(
                                child: _FeatureCard(
                                  icon: Icons.history,
                                  title: '통화기록',
                                  color: const Color(0xFFFF9E80),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CallHistoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _FeatureCard(
                                  icon: Icons.favorite,
                                  title: '건강기록',
                                  color: const Color(0xFFFFAB91),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('건강기록 화면')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // 하단 네비게이션
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // 감정 상태 배너
  Widget _buildEmotionBanner() {
    Color emotionColor = _getEmotionColor();
    String comment = _getEmotionComment();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            emotionColor.withOpacity(0.8),
            emotionColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$userName님의 오늘',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '기분은 ',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currentEmotion,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 중앙 대화 버튼
  Widget _buildChatButton() {
    return GestureDetector(
      onTap: () {
        debugPrint('[HOME] 영상통화 버튼 클릭');
        widget.onStartCall();
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
          borderRadius: BorderRadius.circular(20),
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

  // 하단 네비게이션
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
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          _buildNavItem(
            icon: Icons.insert_chart,
            label: '감정기록',
            isSelected: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('감정기록 화면')),
              );
            },
          ),
          _buildNavItem(
            icon: Icons.settings,
            label: '설정',
            isSelected: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              widget.onOpenSettings();
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

  // 감정에 따른 색상 반환
  Color _getEmotionColor() {
    switch (emotionLevel) {
      case '긍정':
        return const Color(0xFF66BB6A); // 따뜻한 초록
      case '보통':
        return const Color(0xFFFFB74D); // 따뜻한 주황
      case '부정':
        return const Color(0xFF64B5F6); // 따뜻한 파랑
      case '심각':
        return const Color(0xFFEF5350); // 따뜻한 빨강
      default:
        return Colors.grey;
    }
  }

  // 감정에 따른 코멘트 반환
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
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
          children: [
            Icon(
              icon,
              size: 42,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}