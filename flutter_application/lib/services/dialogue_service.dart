// lib/services/dialogue_service.dart

import 'dart:convert';
import 'dart:typed_data';

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
  final uri = Uri.parse("$baseUrl/dialogue/speak");

  // multipart/form-data 요청 생성
  final request = http.MultipartRequest("POST", uri);

  // 1) 음성 파일 (audio_file)
  request.files.add(
    http.MultipartFile.fromBytes(
      'audio_file',
      audioBytes,
      filename: 'voice.wav',
    ),
  );

  // 2) 프레임 이미지들 (frames 배열)
  for (int i = 0; i < frameBytesList.length; i++) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'frames',
        frameBytesList[i],
        filename: 'frame_$i.jpg',
      ),
    );
  }

  // 3) user_id 필드
  request.fields['user_id'] = userId.toString();

  // 4) 요청 보내기
  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode != 200) {
    throw Exception("말동이 서버 오류: ${response.statusCode} / ${response.body}");
  }

  // 5) JSON 파싱 → DialogueResponse
  final Map<String, dynamic> jsonData = jsonDecode(response.body);
  final dialogue = DialogueResponse.fromJson(jsonData);

  // 6) TTS base64 → bytes 디코딩 후 재생
  await _playTtsFromBase64(dialogue.ttsAudioBase64);

  return dialogue;
}

/// base64로 받은 MP3를 재생하는 내부 함수
Future<void> _playTtsFromBase64(String base64Audio) async {
  if (base64Audio.isEmpty) return;

  final bytes = base64Decode(base64Audio); // Uint8List
  // 혹시 기존에 재생 중이면 정지
  await maldongTtsPlayer.stop();

  // BytesSource 로 바로 재생
  await maldongTtsPlayer.play(BytesSource(bytes));
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
  final Map<String, dynamic> jsonData =
      jsonDecode(utf8.decode(response.bodyBytes));
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
  final Map<String, dynamic> jsonData =
      jsonDecode(utf8.decode(response.bodyBytes));
  return Session.fromJson(jsonData);
}
