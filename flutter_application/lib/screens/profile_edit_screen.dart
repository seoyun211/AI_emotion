import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'settings_screen.dart';

// 🔥 백엔드 주소 (프로젝트 전체에서 쓰는 baseUrl과 맞춰줘)
// const String baseUrl = 'http://10.0.2.2:8000';
const String baseUrl = 'http://localhost:8000';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthController;

  bool _isLoading = true;        // 프로필 불러오는 중
  bool _isSaving = false;        // 저장 중
  String? _errorMessage;         // 에러 메시지

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _birthController = TextEditingController();

    _loadProfile();  // ✅ 앱 시작 시 DB에서 내 정보 불러오기
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  // ================================
  // 1) DB에서 내 프로필 정보 불러오기
  // ================================
  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('access_token');

      if (userId == null || token == null) {
        setState(() {
          _errorMessage = '로그인 정보가 없습니다. 다시 로그인 해주세요.';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('$baseUrl/api/v1/users/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;

        // 백엔드에서 내려주는 필드 이름에 맞춰서 사용
        // 예시: { "user_id": 1, "username": "...", "user_phone": "...", "birth_date": "1950-01-01", ... }
        setState(() {
          _nameController.text = data['username'] ?? '사용자';
          _phoneController.text = data['user_phone'] ?? '';
          _birthController.text = data['birth_date'] ?? '';

          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        String message = '프로필 정보를 불러오지 못했습니다.';
        try {
          final err = jsonDecode(utf8.decode(response.bodyBytes));
          if (err is Map && err['detail'] != null) {
            message = err['detail'].toString();
          }
        } catch (_) {}

        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '프로필 정보를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  // ================================
  // 2) 프로필 저장(수정) → DB로 전송
  // ================================
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호를 입력해주세요')),
      );
      return;
    }

    if (_birthController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('access_token');

      if (userId == null || token == null) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인 해주세요.')),
        );
        return;
      }

      final uri = Uri.parse('$baseUrl/api/v1/users/$userId');

      // 백엔드에서 기대하는 필드명에 맞춰서 body 구성
      // 현재 DB 스키마: username, user_phone, birth_date 컬럼 존재
      final body = jsonEncode({
        'username': _nameController.text.trim(),
        'user_phone': _phoneController.text.trim(),
        'birth_date': _birthController.text.trim(), // "YYYY-MM-DD"
      });

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // username을 SharedPreferences에도 반영
        await prefs.setString('username', _nameController.text.trim());

        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정보를 저장했어요'),
            duration: Duration(seconds: 1),
          ),
        );

        // 약간의 딜레이 후 뒤로 가기
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        String message = '정보 저장에 실패했습니다.';
        try {
          final err = jsonDecode(utf8.decode(response.bodyBytes));
          if (err is Map && err['detail'] != null) {
            message = err['detail'].toString();
          }
        } catch (_) {}

        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('정보 저장 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // ================================
  // 3) UI
  // ================================
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF9800),
                ),
              )
            : _errorMessage != null
                ? _buildErrorView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '기본 정보 수정',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '내 정보를 수정해주세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8D6E63),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 프로필 이미지
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF9800).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Color(0xFFFF9800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 이름 입력
                        _buildTextField(
                          controller: _nameController,
                          label: '이름',
                          hint: '홍길동',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 24),

                        // 전화번호 입력
                        _buildTextField(
                          controller: _phoneController,
                          label: '전화번호',
                          hint: '010-1234-5678',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),

                        // 생년월일 입력
                        _buildTextField(
                          controller: _birthController,
                          label: '생년월일',
                          hint: 'YYYY-MM-DD',
                          icon: Icons.cake,
                          keyboardType: TextInputType.datetime,
                        ),
                        const SizedBox(height: 40),

                        // 저장 버튼
                        GestureDetector(
                          onTap: _isSaving ? null : _saveProfile,
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
                                  color:
                                      const Color(0xFFFF9800).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isSaving
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    '저장하기',
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Color(0xFF8D6E63)),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF8D6E63),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D4037),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFFF9800), size: 24),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFFF9800),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
