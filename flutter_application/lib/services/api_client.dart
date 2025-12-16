// lib/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._(); // private 생성자

  static final Dio dio = Dio(
    BaseOptions(
      // 👉 에뮬레이터 기준
      baseUrl: 'http://127.0.0.1:8000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
}
