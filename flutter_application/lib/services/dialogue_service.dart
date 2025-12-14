// lib/services/dialogue_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart'; // ✅ DateTime 포맷팅을 위해 추가 (선택 사항이지만 안전함)

import '../models/dialogue_response.dart';
import '../models/session.dart'; // ✅ Session 모델 임포트

/// 🔗 말동이 백엔드 베이스 URL
const String baseUrl = "http://localhost:8000";

/// 전역 TTS 플레이어 (한 개만 만들어서 재사용)
final AudioPlayer maldongTtsPlayer = AudioPlayer();

/// 🎙 음성 + 프레임을 백엔드로 보내고,
///    LLM 답변 + TTS 오디오를 받아서 바로 재생까지 하는 함수
Future<DialogueResponse> sendToMaldongAndPlayTts({
  required Uint8List audioBytes,
  required List<Uint8List> frameBytesList,
  required int userId,
}) async {
  try {
    final uri = Uri.parse('$apiBaseUrl/dialogue/speak?user_id=$userId');
    debugPrint('[DialogueService] 요청 시작 → $uri');

    final request = http.MultipartRequest('POST', uri);

    // 🔊 음성 파일 (필수: audio_file)
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio_file',
        audioBytes,
        filename: 'chunk.m4a',
      ),
    );

    // 📸 프레임들 (선택: 0개여도 됨)
    for (int i = 0; i < frameBytesList.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'frames',
          frameBytesList[i],
          filename: 'frame_$i.jpg',
        ),
      );
    }

    debugPrint(
        '[DialogueService] files 개수 = ${request.files.length} (audio + frames)');

    // 실제 전송
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint(
        '[DialogueService] status = ${response.statusCode}, reason = ${response.reasonPhrase}');
    debugPrint('[DialogueService] body = ${response.body}');

    if (response.statusCode != 200) {
      debugPrint('[DialogueService] 서버 오류, TTS 재생 스킵');
      return;
    }

    // JSON 파싱
    final Map<String, dynamic> data =
        json.decode(utf8.decode(response.bodyBytes));

    final emotion = data['emotion'];
    final confidence = data['confidence'];
    final riskScore = data['risk_score'];
    final reply = data['llm_reply'];
    final ttsBase64 = data['tts_audio_base64'];

    debugPrint(
        '[DialogueService] emotion=$emotion, conf=$confidence, risk=$riskScore');
    debugPrint('[DialogueService] llm_reply=$reply');

    if (ttsBase64 == null || (ttsBase64 as String).isEmpty) {
      debugPrint('[DialogueService] TTS base64 없음 → 재생 안 함');
      return;
    }

    // 🔊 base64 → bytes → 재생
    final bytes = base64Decode(ttsBase64 as String);
    debugPrint('[DialogueService] TTS bytes length = ${bytes.length}');

    // 기존 재생 중이면 정지
    await _ttsPlayer.stop();

    // 로컬 메모리 재생
    await _ttsPlayer.play(
      BytesSource(bytes),
    );
    debugPrint('[DialogueService] TTS 재생 시작');

  } catch (e, st) {
    debugPrint('[DialogueService] 예외 발생: $e');
    debugPrint('[DialogueService] stack: $st');
  }
}

// ------------------------------------------------------------------
// ⭐ 1. 통화 세션 시작 (POST /dialogue/session/start) - ✅ 새로 추가됨
// ------------------------------------------------------------------

/// 통화 시작 시 세션 레코드를 생성하고 session_id를 반환합니다.
Future<Session> startSession({required int userId}) async {
  final uri = Uri.parse("$baseUrl/api/v1/dialogue/session/start");
  
  // NOTE: 백엔드 라우터는 user_id를 쿼리 파라미터로 받도록 설계되었습니다.
  final response = await http.post(
    uri.replace(queryParameters: {'user_id': userId.toString()}),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
        "세션 시작 실패: ${response.statusCode} / ${utf8.decode(response.bodyBytes)}");
  }

  // SessionResponse 스키마에 따라 응답을 파싱합니다.
  final Map<String, dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
  return Session.fromJson(jsonData);
}


// ------------------------------------------------------------------
// ⭐ 2. 통화 세션 종료 및 녹취록 저장 (POST /dialogue/session/end)
// ------------------------------------------------------------------

/// 통화 종료 시 세션 레코드를 업데이트하고 최종 녹취록을 저장합니다.
Future<Session> endSession({
  required int sessionId,
  required int userId,
  required String fullTranscript, // ✅ STT로 누적된 전체 녹취록
}) async {
  final uri = Uri.parse("$baseUrl/api/v1/dialogue/session/end");

  // NOTE: 백엔드 라우터는 session_id, user_id, full_transcript를 쿼리 파라미터로 받도록 설계되었습니다.
  final queryParams = {
    'session_id': sessionId.toString(),
    'user_id': userId.toString(),
    'full_transcript': fullTranscript, 
  };
  
  final response = await http.post(
    uri.replace(queryParameters: queryParams),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
        "세션 종료 및 녹취록 저장 실패: ${response.statusCode} / ${utf8.decode(response.bodyBytes)}");
  }

  // SessionResponse 스키마에 따라 업데이트된 응답을 파싱합니다.
  final Map<String, dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
  return Session.fromJson(jsonData);
}