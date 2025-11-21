import 'package:flutter/material.dart';
import 'call_history_screen.dart';
import 'settings_screen.dart';
import '../screens/video_call_screen.dart';
import '../maldong_avatar.dart';
import 'emotion_recode_screen.dart';

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
                    _buildEmotionBanner(),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          _buildChatButton(),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: _FeatureCard(
                                  icon: Icons.history,
                                  title: '통화기록',
                                  color: const Color(0xFFFF9800),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CallHistoryScreen(),
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
                                  color: const Color(0xFFFFB74D),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('건강기록 화면')),
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
                        Text(
                          currentEmotion,
                          style: TextStyle(
                            fontSize: 28,
                            color: emotionColor,
                            fontWeight: FontWeight.bold,
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
            label: '감정기록',
            isSelected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
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
              setState(() => _selectedIndex = 2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onBack: () {
                      Navigator.pop(context);
                    },
                    onLogout: () {
                      Navigator.pop(context);
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(width: 12),
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
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}