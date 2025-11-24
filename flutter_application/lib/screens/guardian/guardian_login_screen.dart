import 'package:flutter/material.dart';
import 'guardian_signup_screen.dart';

class GuardianLoginScreen extends StatefulWidget {
  const GuardianLoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  final VoidCallback onLoginSuccess;

  @override
  State<GuardianLoginScreen> createState() => _GuardianLoginScreenState();
}

class _GuardianLoginScreenState extends State<GuardianLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호와 비밀번호를 입력해주세요')),
      );
      return;
    }

    // TODO: 실제 로그인 로직 (userType: 'guardian')
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('보호자 로그인 성공!')),
    );

    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.family_restroom,
                      color: Color(0xFF66BB6A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '보호자 로그인',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '다시 만나서 반가워요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 60),
              _buildTextField(
                label: '전화번호',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                hintText: '010-0000-0000',
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: '비밀번호',
                controller: _passwordController,
                obscure: true,
                hintText: '••••••••',
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF66BB6A).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    '로그인',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuardianSignUpScreen(
                          onSignUpSuccess: widget.onLoginSuccess,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '계정이 없으신가요? 회원가입',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF66BB6A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D4037),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF66BB6A), width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}