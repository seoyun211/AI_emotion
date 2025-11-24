import 'package:flutter/material.dart';
import 'guardian_login_screen.dart';

class GuardianSignUpScreen extends StatefulWidget {
  final VoidCallback? onSignUpSuccess;
  const GuardianSignUpScreen({super.key, this.onSignUpSuccess});

  @override
  State<GuardianSignUpScreen> createState() => _GuardianSignUpScreenState();
}

class _GuardianSignUpScreenState extends State<GuardianSignUpScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _elderlyPhoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _relationshipController.dispose();
    _elderlyPhoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _relationshipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요')),
      );
      return;
    }

    // TODO: 실제 회원가입 로직 (userType: 'guardian')
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('보호자 회원가입 완료!')),
    );

    widget.onSignUpSuccess?.call();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianLoginScreen(
          onLoginSuccess: widget.onSignUpSuccess ?? () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
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
                    '보호자 회원가입',
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
                '어르신을 돌봐드려요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                label: '이름',
                controller: _nameController,
                hintText: '김보호',
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: '관계',
                controller: _relationshipController,
                hintText: '아들, 딸, 며느리 등',
              ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 20),

              _buildTextField(
                label: '어르신 전화번호 (선택)',
                controller: _elderlyPhoneController,
                keyboardType: TextInputType.phone,
                hintText: '010-1234-5678',
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
                    '가입하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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