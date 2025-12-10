// lib/services/dialogue_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

// ✅ 반드시 VideoCallScreen의 baseUrl 과 같게!
const String apiBaseUrl = 'http://localhost:8000';

// 말동이 TTS 재생용 (전역으로 하나만 사용)
final AudioPlayer _ttsPlayer = AudioPlayer();

/// 감정 분석 + LLM + TTS:
///  - audioBytes: 1~2초 짧은 음성
///  - frameBytesList: 얼굴 프레임 이미지들 (jpg/png 바이트)
///  - userId: 감정 DB 저장용 사용자 ID
Future<void> sendToMaldongAndPlayTts({
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
