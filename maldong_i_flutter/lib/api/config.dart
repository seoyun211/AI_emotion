// lib/api/config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:5000';
  static const String apiBase = 'http://localhost:5000/api';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}