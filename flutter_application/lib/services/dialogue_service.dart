// lib/services/dialogue_service.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import '../models/dialogue_response.dart';
import '../models/session.dart';

/// ✅ 에뮬레이터에서 PC(호스트) FastAPI로 접근
/// - Android Emulator: 10.0.2.2
/// - 실제 폰: PC의 로컬 IP (예: 192.168.34.40)
const String baseUrl = "http://10.0.2.2:8000";

/// ✅ 백엔드가 include_router(..., prefix="/api/v1") 형태라면 이 prefix를 사용
const String apiPrefix = "/api/v1";

final AudioPlayer maldongTtsPlayer = AudioPlayer();

/// 🎙 음성 + 프레임 → /dialogue/speak 호출 → TTS 재생
Future<DialogueResponse> sendToMaldongAndPlayTts({
  required Uint8List audioBytes,
  required List<Uint8List> frameBytesList,
  required int userId,
}) async {
  final uri = Uri.parse("$baseUrl$apiPrefix/dialogue/speak");

  final request = http.MultipartRequest("POST", uri);

  // 1) audio_file
  request.files.add(
    http.MultipartFile.fromBytes(
      'audio_file',
      audioBytes,
      filename: 'voice.m4a', // ✅ 실제로는 m4a를 보내는 경우가 많아서 이름도 맞춰줌
    ),
  );

  // 2) frames
  for (int i = 0; i < frameBytesList.length; i++) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'frames',
        frameBytesList[i],
        filename: 'frame_$i.jpg',
      ),
    );
  }

  // 3) user_id (✅ Form(None)으로 받게 바꿨으니 이게 먹는다)
  request.fields['user_id'] = userId.toString();

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode != 200) {
    throw Exception(
      "말동이 서버 오류: ${response.statusCode} / ${utf8.decode(response.bodyBytes)}",
    );
  }

  final Map<String, dynamic> jsonData =
      jsonDecode(utf8.decode(response.bodyBytes));

  final dialogue = DialogueResponse.fromJson(jsonData);

  // 6) TTS 재생
  await _playTtsFromBase64(dialogue.ttsAudioBase64);

  return dialogue;
}

Future<void> _playTtsFromBase64(String base64Audio) async {
  if (base64Audio.isEmpty) return;

  final bytes = base64Decode(base64Audio);

  await maldongTtsPlayer.stop();
  await maldongTtsPlayer.play(BytesSource(bytes));
}

/// -------------------------
/// ✅ Session start / end
/// -------------------------

Future<Session> startSession({required int userId}) async {
  final uri = Uri.parse("$baseUrl$apiPrefix/dialogue/session/start")
      .replace(queryParameters: {'user_id': userId.toString()});

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode != 200) {
    throw Exception(
      "세션 시작 실패: ${response.statusCode} / ${utf8.decode(response.bodyBytes)}",
    );
  }

  final Map<String, dynamic> jsonData =
      jsonDecode(utf8.decode(response.bodyBytes));
  return Session.fromJson(jsonData);
}

Future<Session> endSession({
  required int sessionId,
  required int userId,
  required String fullTranscript,
}) async {
  final uri = Uri.parse("$baseUrl$apiPrefix/dialogue/session/end").replace(
    queryParameters: {
      'session_id': sessionId.toString(),
      'user_id': userId.toString(),
      'full_transcript': fullTranscript,
    },
  );

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode != 200) {
    throw Exception(
      "세션 종료 실패: ${response.statusCode} / ${utf8.decode(response.bodyBytes)}",
    );
  }

  final Map<String, dynamic> jsonData =
      jsonDecode(utf8.decode(response.bodyBytes));
  return Session.fromJson(jsonData);
}
