import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:http_parser/http_parser.dart'; 

// dialogue_response.dart는 사용하지 않으므로 삭제합니다.

/// 🔗 말동이 백엔드 베이스 URL
const String baseUrl = "http://localhost:8000";

/// 전역 TTS 플레이어 (한 개만 만들어서 재사용)
final AudioPlayer maldongTtsPlayer = AudioPlayer();

// ★ 새로운 응답 모델 정의 (STT 텍스트와 LLM 텍스트를 담기 위함)
class DialogueTexts {
  final String userSttText;
  final String maldongResponseText;
  DialogueTexts({required this.userSttText, required this.maldongResponseText});
}

// -----------------------------------------------------------------
// 1. 감정 분석 루프용 (멀티모달) - PTT에서는 사용 안 함
// -----------------------------------------------------------------
Future<String?> sendToMaldongAndPlayTts({
  required Uint8List audioBytes,
  required List<Uint8List> frameBytesList,
  required int userId,
  required int? sessionId, // 세션 ID 추가
}) async {
  // 이 함수는 감정 분석 루프에 사용되며, LLM 응답 텍스트만 반환합니다.
  final uri = Uri.parse("$baseUrl/dialogue/speak");

  final request = http.MultipartRequest("POST", uri);

  request.files.add(
    http.MultipartFile.fromBytes(
      'audio_file',
      audioBytes,
      filename: 'voice.wav',
    ),
  );

  for (int i = 0; i < frameBytesList.length; i++) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'frames',
        frameBytesList[i],
        filename: 'frame_$i.jpg',
      ),
    );
  }

  request.fields['user_id'] = userId.toString();
  
  // 세션 ID가 있다면 필드에 추가 (DB 기록용)
  if (sessionId != null) {
      request.fields['session_id'] = sessionId.toString();
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode != 200) {
    throw Exception(
        "말동이 서버 오류: ${response.statusCode} / ${response.body}");
  }

  // TTS base64 → bytes 디코딩 후 재생 (이전 방식 유지)
  try {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      // TTS base64를 받았다고 가정하고 재생
      final ttsBase64 = jsonData['tts_audio_base64'] as String;
      await _playTtsFromBase64(ttsBase64);
      return jsonData['maldong_response_text'] as String; // 응답 텍스트 반환
  } catch (e) {
      // JSON 파싱 실패 시
      return "응답 처리 중 오류 발생";
  }
}

// -----------------------------------------------------------------
// 2. PTT 대화용 (세션 ID 기반) - UI에 STT 결과 표시 용도
// -----------------------------------------------------------------

Future<DialogueTexts?> sendAudioForDialogue({
  required Uint8List audioBytes,
  required int sessionId,
}) async {
  // 엔드포인트 변경: /api/v1/calls/dialogue/{session_id}
  final uri = Uri.parse("$baseUrl/api/v1/calls/dialogue/$sessionId");

  final request = http.MultipartRequest("POST", uri);

  request.files.add(
    http.MultipartFile.fromBytes(
      'audio_file',
      audioBytes,
      filename: 'user_voice.m4a',
      contentType: MediaType('audio', 'm4a'), // ★ MediaType 임포트 문제 해결
    ),
  );

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode != 200) {
    final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception("서버 오류: ${response.statusCode} / ${errorBody['error']}");
  }

  // 3) 헤더에서 텍스트 추출 (STT와 LLM 텍스트 모두 추출)
  final userSttText = response.headers['x-user-stt-text'];
  final maldongResponseText = response.headers['x-maldong-text'];

  if (userSttText == null || maldongResponseText == null) {
      throw Exception("서버 응답 헤더에 텍스트 정보(STT/LLM)가 부족합니다.");
  }

  // 4) 응답 본문 (MP3 바이트) 재생
  final ttsAudioBytes = response.bodyBytes;
  await _playTtsFromBytes(ttsAudioBytes);

  return DialogueTexts(
      userSttText: userSttText, 
      maldongResponseText: maldongResponseText
  );
}

// =========================
// 헬퍼 함수
// =========================

/// base64로 받은 MP3를 재생하는 내부 함수 (감정 분석 루프용)
Future<void> _playTtsFromBase64(String base64Audio) async {
  if (base64Audio.isEmpty) return;

  final bytes = base64Decode(base64Audio); // Uint8List
  await maldongTtsPlayer.stop();
  await maldongTtsPlayer.play(BytesSource(bytes));
}

/// 바이트 배열로 받은 MP3를 재생하는 내부 함수 (PTT 대화용)
Future<void> _playTtsFromBytes(Uint8List bytes) async {
  if (bytes.isEmpty) return;
  await maldongTtsPlayer.stop();
  await maldongTtsPlayer.play(BytesSource(bytes));
}