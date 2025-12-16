import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'guardian/guardian_home_screen.dart';
import '../maldong_avatar.dart';
import 'signup_screen.dart';

// const String baseUrl = 'http://10.0.2.2:8000';
const String baseUrl = 'http://localhost:8000';

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

    final loginData = {
      'user_phone': _phoneController.text,
      'password': _passwordController.text,
    };

    try {
      final url = Uri.parse('$baseUrl/api/v1/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(loginData),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final role = data['role'];
        final username = data['username'] ?? '사용자';
        final userId = data['user_id'];
        final accessToken = data['access_token'];

        print('로그인 성공: userId=$userId, role=$role, username=$username');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken ?? '');
        await prefs.setString('user_role', role);
        await prefs.setInt('user_id', userId ?? 0);
        await prefs.setString('username', username);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 성공! $username님 환영합니다 🎉'),
              backgroundColor: const Color(0xFF66BB6A),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(
            {
              'user_id': userId,
              'access_token': accessToken,
              'role': role,
              'username': username,
            },
          );
        } else {
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          if (role == 'ward') {
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GuardianHomeScreen(
                  guardianUserId: userId,
                  accessToken: accessToken,
                  onOpenSettings: () {
                    print('설정 열기');
                  },
                  onLogout: () async {
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

              // ✅ 회원가입 버튼 - SignUpScreen의 생성자에 맞게 수정
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(
                                onSignUpSuccess: (String role) {
                                  // 회원가입 성공 후 로그인 화면으로 돌아왔을 때
                                  print('회원가입 완료: role=$role');
                                  
                                  // 회원가입 성공 메시지 표시
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        role == 'ward' 
                                            ? '어르신 계정 생성 완료! 로그인해주세요 😊'
                                            : '보호자 계정 생성 완료! 로그인해주세요 😊'
                                      ),
                                      backgroundColor: role == 'ward'
                                          ? const Color(0xFFFF9800)
                                          : const Color(0xFF66BB6A),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
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