import 'package:flutter/material.dart';
import 'signup_screen.dart';


class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGoToSignUp;
  //final VoidCallback onLoginSuccess;

  const WelcomeScreen({
    Key? key,
     required this.onGoToSignUp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8F0), Color(0xFFFFE0B2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 100,
                      color: Color(0xFFFF9800),
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    '말동이',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    '따뜻한 대화, 함께해요',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF8D6E63),
                    ),
                  ),

                  const Spacer(),

                  // 회원가입 버튼
                  _buildButton(
                    text: '말동이가 처음이에요',
                    isPrimary: true,
                    onTap: onGoToSignUp,  
                  ),

                  const SizedBox(height: 16),

                  // 로그인 → 홈 화면 이동
                  _buildButton(
                    text: '말동이 사용 중이에요',
                    isPrimary: false,
                    onTap: () {
                      // TODO: 로그인 후 홈 화면 이동 로직 추가 예정
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                )
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPrimary ? Colors.white : const Color(0xFFFF9800),
          ),
        ),
      ),
    );
  }
}
