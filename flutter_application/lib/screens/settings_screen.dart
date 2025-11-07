import 'package:flutter/material.dart';
import 'font_size_screen.dart';

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
      body: Column(
        children: [
          // 상단 그라디언트 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    '뒤로가기',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '설정',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      child: Column(
                        children: [
                          _SettingsItem(
                            icon: Icons.person,
                            title: '프로필 설정',
                            onTap: () {},
                          ),
                          const Divider(height: 0),
                          _SettingsItem(
                            icon: Icons.notifications,
                            title: '보호자 연결',
                            onTap: () {},
                          ),
                          const Divider(height: 0),
                          _SettingsItem(
                            icon: Icons.text_increase,
                            title: '글씨 크기',
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => const FontSizeScreen(),
                                )

                              );
                            },
                          ),
                          const Divider(height: 0),
                          _SettingsItem(
                            icon: Icons.settings,
                            title: '앱 설정',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          '로그아웃',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
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
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, size: 30, color: Colors.grey[800]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 30),
      onTap: onTap,
    );
  }
}
