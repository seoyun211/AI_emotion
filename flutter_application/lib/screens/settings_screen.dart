import 'package:flutter/material.dart';
import 'font_size_screen.dart';
import 'guardian_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '설정',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '앱 설정을 관리해요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 40),
              
              // 설정 카드
              Container(
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
                    _SettingsItem(
                      icon: Icons.person,
                      title: '프로필 설정',
                      onTap: () {},
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    _SettingsItem(
                      icon: Icons.family_restroom,
                      title: '보호자 수정',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GuardianScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    _SettingsItem(
                      icon: Icons.text_increase,
                      title: '글씨 크기',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FontSizeScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    _SettingsItem(
                      icon: Icons.settings,
                      title: '앱 설정',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 로그아웃 버튼
              GestureDetector(
                onTap: onLogout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '로그아웃',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: Color(0xFF8D6E63),
            ),
          ],
        ),
      ),
    );
  }
}