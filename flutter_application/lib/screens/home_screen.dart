import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onStartCall;   // ✅ 콜백

  const HomeScreen({
    super.key,
    required this.onOpenSettings,
    required this.onStartCall,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 배경 그라디언트
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 인사 + 설정
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '안녕하세요 👋',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: onOpenSettings,
                          icon: const Icon(
                            Icons.settings,
                            size: 30,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 메인 카드
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        // 영상 영역
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFCC80),
                                  Color(0xFFFFA726),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.photo_camera,
                                color: Colors.white,
                                size: 80,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 🔶 영상통화 시작 버튼
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFB300),
                                Color(0xFFFF6F00),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              // 디버그용 로그
                              debugPrint('[HOME] 영상통화 버튼 클릭');
                              onStartCall();     // ✅ 여기서 호출!
                            },
                            icon: const Icon(
                              Icons.phone,
                              size: 32,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'AI와 영상통화 시작',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 아래 두 카드
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.chat_bubble_outline,
                          iconColor: Colors.blue,
                          title: '채팅하기',
                          onTap: () {
                            // TODO: 채팅 화면 이동
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.show_chart,
                          iconColor: Colors.green,
                          title: '건강기록',
                          onTap: () {
                            // TODO: 건강 기록 화면 이동
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: iconColor,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            )
          ],
        ),
      ),
    );
  }
}
