// lib/services/user_api.dart
import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class UserApi {
  static final Dio _dio = ApiClient.dio;

  /// 회원 등록
  static Future<UserResponse> createUser(UserCreateRequest request) async {
    final response = await _dio.post(
      '/api/v1/users/',
      data: request.toJson(),
    );

    return UserResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 특정 user_id 조회
  static Future<UserResponse> getUser(int userId) async {
    final response = await _dio.get('/api/v1/users/$userId');
    return UserResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 헬스 체크 (연결 테스트용)
  static Future<String> healthCheck() async {
    final response = await _dio.get('/health');
    return response.data.toString();
  }
}
