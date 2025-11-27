import 'package:flutter/material.dart';

// ============================================
// 첫 화면 - 회원가입 or 로그인만 선택
// ============================================
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGoToSignUp;
  final VoidCallback onGoToLogin;

  const WelcomeScreen({
    Key? key,
    required this.onGoToSignUp,
    required this.onGoToLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFAF5), Color(0xFFFFEDD5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // 앱 로고
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 80,
                    color: Color(0xFFFF9800),
                  ),
                ),

                const SizedBox(height: 32),

                // 앱 이름
                const Text(
                  '말동이',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // 서브타이틀
                const Text(
                  '따뜻한 대화, 함께해요',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8D6E63),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(flex: 2),

                // 질문 문구
                const Text(
                  '말동이는 처음인가요?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),

                const SizedBox(height: 24),

                // 회원가입 버튼 (오렌지)
                _buildActionButton(
                  context: context,
                  icon: Icons.person_add_rounded,
                  title: '네, 처음이에요',
                  subtitle: '회원가입하고 시작하기',
                  color: const Color(0xFFFF9800),
                  onTap: onGoToSignUp,
                ),

                const SizedBox(height: 12),

                // 로그인 버튼 (초록)
                _buildActionButton(
                  context: context,
                  icon: Icons.login_rounded,
                  title: '이미 사용 중입니다',
                  subtitle: '로그인하기',
                  color: const Color(0xFF66BB6A),
                  onTap: onGoToLogin,
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}