import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback? onSignUpSuccess; 
  const SignUpScreen({super.key, this.onSignUpSuccess});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요')),
      );
      return;
    }
    
    // TODO: 실제 회원가입 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입 완료!')),
    );
    

    if (widget.onSignUpSuccess != null) {
      widget.onSignUpSuccess!();
    }
  
    // 로그인 화면으로 이동
    // TODO: 로그인 화면 import 후 아래 주석 해제
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => const LoginScreen()),
    // );
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
              const Text(
                '회원가입',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '말동이와 함께 시작해요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 40),
              
              _buildTextField(
                label: '이름',
                controller: _nameController,
                hintText: '홍길동',
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
                label: '보호자 전화번호',
                controller: _guardianPhoneController,
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.3),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}