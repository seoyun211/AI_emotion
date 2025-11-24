import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGoToElderlySignUp;
  final VoidCallback onGoToElderlyLogin;
  final VoidCallback onGoToGuardianSignUp;
  final VoidCallback onGoToGuardianLogin;

  const WelcomeScreen({
    Key? key,
    required this.onGoToElderlySignUp,
    required this.onGoToElderlyLogin,
    required this.onGoToGuardianSignUp,
    required this.onGoToGuardianLogin,
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

                const Spacer(flex: 3),

                // 어르신 버튼
                _buildUserTypeButton(
                  context: context,
                  icon: Icons.person_rounded,
                  title: '어르신',
                  subtitle: '말동이와 대화하고 싶어요',
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserTypeSelectionScreen(
                          isElderly: true,
                          onGoToSignUp: onGoToElderlySignUp,
                          onGoToLogin: onGoToElderlyLogin,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 보호자 버튼
                _buildUserTypeButton(
                  context: context,
                  icon: Icons.family_restroom_rounded,
                  title: '보호자',
                  subtitle: '어르신을 돌보고 싶어요',
                  color: const Color(0xFF66BB6A),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserTypeSelectionScreen(
                          isElderly: false,
                          onGoToSignUp: onGoToGuardianSignUp,
                          onGoToLogin: onGoToGuardianLogin,
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton({
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

// 회원가입/로그인 선택 화면
class UserTypeSelectionScreen extends StatelessWidget {
  final bool isElderly;
  final VoidCallback onGoToSignUp;
  final VoidCallback onGoToLogin;

  const UserTypeSelectionScreen({
    Key? key,
    required this.isElderly,
    required this.onGoToSignUp,
    required this.onGoToLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isElderly ? const Color(0xFFFF9800) : const Color(0xFF66BB6A);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 아이콘
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isElderly ? Icons.person_rounded : Icons.family_restroom_rounded,
                  size: 80,
                  color: color,
                ),
              ),

              const SizedBox(height: 32),

              // 타이틀
              Text(
                isElderly ? '어르신 계정' : '보호자 계정',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),

              const SizedBox(height: 12),

              // 서브타이틀
              Text(
                isElderly ? '말동이와 대화를 시작해요' : '어르신을 돌봐드려요',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),

              const Spacer(flex: 3),

              // 회원가입 버튼
              _buildButton(
                text: '처음 사용해요',
                isPrimary: true,
                color: color,
                onTap: () {
                  Navigator.pop(context);
                  onGoToSignUp();
                },
              ),

              const SizedBox(height: 12),

              // 로그인 버튼
              _buildButton(
                text: '이미 계정이 있어요',
                isPrimary: false,
                color: color,
                onTap: () {
                  Navigator.pop(context);
                  onGoToLogin();
                },
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: isPrimary ? null : Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}