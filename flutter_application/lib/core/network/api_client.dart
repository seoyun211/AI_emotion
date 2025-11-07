import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(String baseUrl)
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // 보호자 회원가입
  Future<void> registerGuardian({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/api/v1/auth/register',
      data: {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      },
    );
    print('회원가입 응답: ${res.data}');
  }

  // 보호자 로그인
  Future<String> loginGuardian({
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post(
      '/api/v1/auth/login',
      data: {
        'username': phone,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType, // OAuth2 방식
      ),
    );
    print('로그인 응답: ${res.data}');
    return res.data['access_token'] as String;
  }
}
