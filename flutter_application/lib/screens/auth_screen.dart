import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;

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
    // TODO: 실제 로그인/회원가입 로직 연결
    if (_phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      return;
    }
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로고 + 제목
                  const Icon(Icons.favorite, color: Colors.redAccent, size: 100),
                  const SizedBox(height: 20),
                  const Text(
                    '말동이',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '말동이 함께하는 따뜻한 대화',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 카드 박스
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
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLoginMode ? '로그인' : '회원가입',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),

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

                        // 회원가입일 때만 표시되는 부분
                        if (!_isLoginMode) ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: '이름',
                            controller: _nameController,
                            hintText: '홍길동',
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: '보호자 전화번호',
                            controller: _guardianPhoneController,
                            keyboardType: TextInputType.phone,
                            hintText: '010-1234-5678',
                          ),
                        ],

                        const SizedBox(height: 30),

                        // 버튼
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _submit,
                            child: Text(
                              _isLoginMode ? '로그인' : '가입하기',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                            });
                          },
                          child: Text(
                            _isLoginMode ? '회원가입' : '로그인으로 돌아가기',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
        Text(label,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.deepOrange),
            ),
          ),
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
