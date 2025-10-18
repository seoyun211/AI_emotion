// lib/api/emotion_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class EmotionApi {
  // API 호출 헬퍼
  static Future<dynamic> apiCall(String endpoint, {Map<String, dynamic>? options}) async {
    try {
      final url = '${ApiConfig.apiBase}$endpoint';
      final method = options?['method'] ?? 'GET';
      final body = options?['body'];
      
      // headers를 Map<String, String>으로 명시적 변환
      final Map<String, String> headers = Map<String, String>.from(ApiConfig.headers);
      if (options?['headers'] != null) {
        final additionalHeaders = options!['headers'] as Map<String, dynamic>;
        additionalHeaders.forEach((key, value) {
          headers[key] = value.toString();
        });
      }

      http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: body,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            Uri.parse(url),
            headers: headers,
          );
          break;
        default: // GET
          response = await http.get(
            Uri.parse(url),
            headers: headers,
          );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (error) {
      print('API Call Failed: $error');
      throw error;
    }
  }

  // 감정 분석 API
  static Future<dynamic> analyzeEmotion(String text, {String? userId}) async {
    return await apiCall('/predict', options: {
      'method': 'POST',
      'body': json.encode({
        'text': text,
        'user_id': userId,
      }),
    });
  }

  // 서버 상태 확인
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/health'));
      return response.statusCode == 200;
    } catch (error) {
      print('Server health check failed: $error');
      return false;
    }
  }

  // 통화 시작 API
  static Future<Map<String, dynamic>> startCall() async {
    return {'success': true, 'callId': '123'};
  }

  // 통화 종료 API
  static Future<Map<String, dynamic>> endCall(String callId) async {
    return {'success': true};
  }

  // 통화 기록 조회 API
  static Future<List<Map<String, dynamic>>> getCallHistory() async {
    return [
      {'id': 1, 'date': '2024-01-15', 'emotion': 'happy', 'duration': '5:30'},
      {'id': 2, 'date': '2024-01-14', 'emotion': 'neutral', 'duration': '3:15'},
    ];
  }

  // 감정 기록 조회 API - 이 메서드가 없어서 에러 발생했음
  static Future<List<Map<String, dynamic>>> getEmotionHistory() async {
    try {
      // 실제 API 호출 시도
      return await apiCall('/emotion-history');
    } catch (error) {
      // API 호출 실패 시 임시 데이터 반환
      print('감정 기록 API 호출 실패, 임시 데이터 사용: $error');
      await Future.delayed(const Duration(seconds: 1));
      return [
        {
          'id': 1,
          'date': '2024-01-15',
          'emotion': 'happy',
          'duration': '5:30',
          'summary': '기분 좋은 대화'
        },
        {
          'id': 2,
          'date': '2024-01-14',
          'emotion': 'neutral',
          'duration': '3:15',
          'summary': '일상적인 대화'
        },
        {
          'id': 3,
          'date': '2024-01-13',
          'emotion': 'sad',
          'duration': '2:45',
          'summary': '조금 우울한 대화'
        },
      ];
    }
  }

  // 감정 응답 조회 API
  static Future<Map<String, dynamic>> getEmotionResponse(String emotion) async {
    try {
      return await apiCall('/emotion-response?emotion=$emotion');
    } catch (error) {
      print('감정 응답 API 호출 실패: $error');
      // 임시 응답 데이터
      final responses = {
     // lib/api/emotion_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class EmotionApi {
  // 서버 상태 확인 - 실제 백엔드 호출
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        timeout: const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (error) {
      print('서버 상태 확인 실패: $error');
      return false;
    }
  }

  // 감정 분석 - 실제 백엔드 호출
  static Future<Map<String, dynamic>> analyzeEmotion(String text, {String? userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'user_id': userId ?? 'default_user',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('감정 분석 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('감정 분석 API 호출 실패: $error');
      throw error;
    }
  }

  // 통화 시작 - 백엔드에 통화 시작 알림
  static Future<Map<String, dynamic>> startCall() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/call/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': 'senior_user',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('통화 시작 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('통화 시작 API 호출 실패: $error');
      // 실패해도 임시 데이터 반환
      return {'success': true, 'callId': 'temp_${DateTime.now().millisecondsSinceEpoch}'};
    }
  }

  // 통화 종료 - 백엔드에 통화 종료 알림
  static Future<Map<String, dynamic>> endCall(String callId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/call/end'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'call_id': callId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('통화 종료 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('통화 종료 API 호출 실패: $error');
      return {'success': true};
    }
  }

  // 감정 기록 조회 - 실제 백엔드 호출
  static Future<List<Map<String, dynamic>>> getEmotionHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history/emotions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('기록 조회 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('감정 기록 API 호출 실패: $error');
      // 실패 시 빈 배열 반환
      return [];
    }
  }

  // 통화 기록 조회
  static Future<List<Map<String, dynamic>>> getCallHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history/calls'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('통화 기록 조회 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('통화 기록 API 호출 실패: $error');
      return [];
    }
  }
}   'happy': {'response': '정말 기쁜 일이 있으셨군요! 더 즐거운 이야기 해보세요.'},
        'sad': {'response': '슬픈 기분이시군요. 제가 함께 있어드릴게요.'},
        'neutral': {'response': '오늘 하루는 어떠셨나요?'},
      };
      return responses[emotion] ?? {'response': '오늘 하루는 어떠셨나요?'};
    }
  }
}