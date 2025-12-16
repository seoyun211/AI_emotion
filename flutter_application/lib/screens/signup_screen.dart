import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

//const String baseUrl = 'http://10.0.2.2:8000';
const String baseUrl = 'http://127.0.0.1:8000';

// ============================================
// 회원가입 화면 - 역할 선택 포함
// ============================================
class SignUpScreen extends StatefulWidget {
  final Function(String role) onSignUpSuccess;

  const SignUpScreen({
    Key? key,
    required this.onSignUpSuccess,
  }) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _linkedPhoneController = TextEditingController(); // 연동할 전화번호 (보호자용: 어르신 번호, 어르신용: 보호자 번호)
  
  String? _selectedRole; // 'ward' (어르신) or 'guardian' (보호자)
  String? _selectedGender; // 'M' or 'F'
  DateTime? _selectedBirthDate;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1960),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedRole == 'ward' 
                  ? const Color(0xFFFF9800) 
                  : const Color(0xFF66BB6A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  String _formatDateKorean(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('어르신 또는 보호자를 선택해주세요')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성별을 선택해주세요')),
      );
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 선택해주세요')),
      );
      return;
    }

    // 🌟 API 호출 - auth.py의 SignUpRequest 스키마와 일치
    final signupData = {
      'username': _usernameController.text,
      'password': _passwordController.text,
      'user_phone': _phoneController.text,
      'role': _selectedRole, // 'ward' or 'guardian'
      'gender': _selectedGender,
      'birth_date': _selectedBirthDate!.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
      'address': _addressController.text.isEmpty ? null : _addressController.text,
      
      // 🔥 보호자인 경우: ward_phone (어르신 전화번호)
      if (_selectedRole == 'guardian' && _linkedPhoneController.text.isNotEmpty)
        'ward_phone': _linkedPhoneController.text,
      
      // 🔥 어르신인 경우: linked_phone_input (보호자 전화번호) - 선택사항
      if (_selectedRole == 'ward' && _linkedPhoneController.text.isNotEmpty)
        'linked_phone_input': _linkedPhoneController.text,
    };
    
    print('회원가입 데이터: $signupData');
    
    try {
      final url = Uri.parse('$baseUrl/api/v1/auth/signup');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(signupData),
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 회원가입 성공
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedRole == 'ward' 
                  ? '어르신 계정이 생성되었습니다! 🎉' 
                  : '보호자 계정이 생성되었습니다! 🎉'
            ),
            backgroundColor: _selectedRole == 'ward' 
                ? const Color(0xFFFF9800) 
                : const Color(0xFF66BB6A),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // role 정보를 전달
        widget.onSignUpSuccess(_selectedRole!);
        
        // 로그인 화면으로 돌아가기
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        String message = '회원가입에 실패했습니다.';
        try {
          final err = jsonDecode(utf8.decode(response.bodyBytes));
          if (err['detail'] != null) {
            message = err['detail'].toString();
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('네트워크 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('네트워크 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _selectedRole == 'ward' 
        ? const Color(0xFFFF9800) 
        : _selectedRole == 'guardian'
            ? const Color(0xFF66BB6A)
            : const Color(0xFF9E9E9E);

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
          '회원가입',
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
              const SizedBox(height: 8),

              // 역할 선택
              const Text(
                '계정 유형',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildRoleButton(
                      icon: Icons.person_rounded,
                      title: '어르신',
                      role: 'ward',
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleButton(
                      icon: Icons.family_restroom_rounded,
                      title: '보호자',
                      role: 'guardian',
                      color: const Color(0xFF66BB6A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 이름
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '이름',
                  prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 전화번호
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
                  hintText: '010-1234-5678',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
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

              // 🌟 보호자 선택 시: 어르신 전화번호 입력 (필수)
              if (_selectedRole == 'guardian') ...[
                TextFormField(
                  controller: _linkedPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: '어르신 전화번호',
                    prefixIcon: Icon(Icons.elderly, color: primaryColor),
                    hintText: '010-1234-5678',
                    helperText: '연동할 어르신의 전화번호를 입력해주세요 (필수)',
                    helperStyle: TextStyle(
                      color: primaryColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (_selectedRole == 'guardian' && (value == null || value.isEmpty)) {
                      return '어르신 전화번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 🌟 어르신 선택 시: 보호자 전화번호 입력 (선택사항)
              if (_selectedRole == 'ward') ...[
                TextFormField(
                  controller: _linkedPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: '보호자 전화번호 (선택사항)',
                    prefixIcon: Icon(Icons.family_restroom, color: primaryColor),
                    hintText: '010-1234-5678',
                    helperText: '보호자 계정과 연동하려면 입력해주세요',
                    helperStyle: TextStyle(
                      color: primaryColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 비밀번호
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: primaryColor,
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
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 최소 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 성별 선택
              Row(
                children: [
                  Expanded(
                    child: _buildGenderButton('남성', 'M', Icons.male),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderButton('여성', 'F', Icons.female),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 생년월일
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '생년월일',
                    prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  child: Text(
                    _selectedBirthDate == null
                        ? '날짜를 선택하세요'
                        : _formatDateKorean(_selectedBirthDate!),
                    style: TextStyle(
                      color: _selectedBirthDate == null 
                          ? Colors.grey 
                          : const Color(0xFF5D4037),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 주소 (선택사항)
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: '주소 (선택사항)',
                  prefixIcon: Icon(Icons.home_outlined, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildRoleButton({
    required IconData icon,
    required String title,
    required String role,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          // 역할 변경 시 연동 전화번호 초기화
          _linkedPhoneController.clear();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : const Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(String title, String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    final primaryColor = _selectedRole == 'ward' 
        ? const Color(0xFFFF9800) 
        : _selectedRole == 'guardian'
            ? const Color(0xFF66BB6A)
            : const Color(0xFF9E9E9E);
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : const Color(0xFF9E9E9E),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}