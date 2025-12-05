import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // 어르신 홈 화면
import 'guardian/guardian_home_screen.dart'; // 보호자 홈 화면
import '../maldong_avatar.dart'; // 아바타

const String baseUrl = 'http://localhost:8000';

// ============================================
// 로그인 화면
// ============================================
class LoginScreen extends StatefulWidget {
  final Function(String role)? onLoginSuccess;

  const LoginScreen({
    Key? key,
    this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // POST /api/auth/login 에 보낼 데이터
    final loginData = {
      'user_phone': _phoneController.text,
      'password': _passwordController.text,
    };

    try {
      // 1) 로그인 API 호출
      final url = Uri.parse('$baseUrl/api/v1/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      // 2) 응답 상태 코드 체크
      if (response.statusCode == 200) {
        // 예: { "user_id": 123, "role": "ward", "username": "홍길동", "token": "..." }
        final data = jsonDecode(response.body);

        final role = data['role'];      // 'ward' or 'guardian'
        final username = data['username'] ?? '사용자';
        final userId = data['user_id'];
        final token = data['token'];

        // SharedPreferences에 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token ?? '');
        await prefs.setString('user_role', role);
        await prefs.setInt('user_id', userId ?? 0);
        await prefs.setString('username', username);

        // 3) 성공 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 성공! $username님 환영합니다 🎉'),
            backgroundColor: const Color(0xFF66BB6A),
            duration: const Duration(seconds: 2),
          ),
        );

        // 4) 콜백이 있으면 호출
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(role);
        }

        // 5) 화면 전환
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          if (role == 'ward') {
            // 어르신 홈 화면으로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  onStartCall: () {
                    // 화상 통화 시작 로직
                    print('화상 통화 시작');
                  },
                  avatar: const MaldongAvatar(url: 'assets/model.glb'),
                  onOpenSettings: () {
                    // 설정 열기 로직
                    print('설정 열기');
                  },
                ),
              ),
            );
          } else if (role == 'guardian') {
            // 보호자 홈 화면으로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GuardianHomeScreen(
                  onOpenSettings: () {
                    // 설정 열기 로직
                    print('설정 열기');
                  },
                  onLogout: () async {
                    // 로그아웃 처리
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                ),
              ),
            );
          }
        }
      } else {
        // 5) 200 아니면 에러 처리
        String message = '로그인에 실패했습니다.';
        try {
          final err = jsonDecode(response.body);
          if (err['detail'] != null) {
            message = err['detail'];
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      // 6) 네트워크 오류 등
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '로그인',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // 환영 메시지
              const Text(
                '다시 만나서 반가워요!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '전화번호와 비밀번호를 입력해주세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),

              const SizedBox(height: 48),

              // 전화번호
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF66BB6A)),
                  hintText: '010-1234-5678',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '전화번호를 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 비밀번호
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF66BB6A)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF66BB6A),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 회원가입 링크
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // WelcomeScreen으로 돌아가서 회원가입 선택
                  },
                  child: const Text(
                    '계정이 없으신가요? 회원가입',
                    style: TextStyle(
                      color: Color(0xFF8D6E63),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}