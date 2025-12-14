// lib/core/models/session.dart

class Session {
  final int sessionId;
  final int userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  
  // STT 텍스트 저장을 위한 필드 추가 (String? fullTranscript)
  final String? fullTranscript; 

  Session({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.fullTranscript,
  });

  // 백엔드 API 응답 (JSON Map)을 Dart 객체로 변환합니다.
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: json['session_id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationSeconds: json['duration_seconds'],
      fullTranscript: json['full_transcript'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'full_transcript': fullTranscript, 
    };
  }
}