// lib/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._(); // private 생성자

  static final Dio dio = Dio(
    BaseOptions(
      // 👉 에뮬레이터 기준
      baseUrl: 'http://localhost:8000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // ✅ 보호자 알람 조회
  static Future<List<dynamic>> getGuardianAlerts(int guardianId) async {
    final res = await dio.get("/alerts/guardian/$guardianId");
    return res.data as List<dynamic>;
  }

  // ✅ 알람 상태 업데이트 (pending → resolved)
  static Future<void> resolveAlert(int alertId) async {
    await dio.patch("/alerts/$alertId");
  }

  // ✅ 알람 생성 (테스트용)
  static Future<Map<String, dynamic>> checkAndCreateAlert(
      int userId, int chunkId) async {
    final res = await dio.post(
      "/alerts/check",
      queryParameters: {"user_id": userId, "chunk_id": chunkId},
    );
    return res.data as Map<String, dynamic>;
  }
}
