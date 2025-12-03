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
  final Function(Map<String, dynamic>)? onLoginSuccess;

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
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(loginData),
      );

      setState(() => _isLoading = false);

      // 2) 응답 상태 코드 체크
      if (response.statusCode == 200) {
        // 예: { "user_id": 123, "role": "ward", "username": "홍길동", "access_token": "...", "token_type": "bearer" }
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final role = data['role'];                    // 'ward' or 'guardian'
        final username = data['username'] ?? '사용자';
        final userId = data['user_id'];
        final accessToken = data['access_token'];     // ✅ JWT 토큰

        print('로그인 성공: userId=$userId, role=$role, username=$username');

        // SharedPreferences에 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken ?? '');
        await prefs.setString('user_role', role);
        await prefs.setInt('user_id', userId ?? 0);
        await prefs.setString('username', username);

        // 3) 성공 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 성공! $username님 환영합니다 🎉'),
              backgroundColor: const Color(0xFF66BB6A),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // 4) 콜백이 있으면 호출 (main.dart의 _handleLoginSuccess)
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!({
            'user_id': userId,
            'access_token': accessToken,
            'role': role,
            'username': username,
          });
        } else {
          // 5) 콜백이 없으면 직접 화면 전환
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (!mounted) return;
          
          if (role == 'ward') {
            // 어르신 홈 화면으로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  onStartCall: () {
                    print('화상 통화 시작');
                  },
                  avatar: const MaldongAvatar(url: 'assets/model.glb'),
                  onOpenSettings: () {
                    print('설정 열기');
                  },
                ),
              ),
            );
          } else if (role == 'guardian') {
            // ✅ 보호자 홈 화면으로 이동 (필수 파라미터 전달)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GuardianHomeScreen(
                  guardianUserId: userId,        // ✅ 필수
                  accessToken: accessToken,      // ✅ 필수
                  onOpenSettings: () {
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
          final err = jsonDecode(utf8.decode(response.bodyBytes));
          if (err['detail'] != null) {
            message = err['detail'];
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 6) 네트워크 오류 등
      setState(() => _isLoading = false);
      print('로그인 에러: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('네트워크 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                enabled: !_isLoading,
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
                enabled: !_isLoading,
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
                onFieldSubmitted: (_) => _handleLogin(),
              ),

              const SizedBox(height: 32),

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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
                  onPressed: _isLoading ? null : () {
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