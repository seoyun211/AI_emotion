import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import '../models/dialogue_response.dart';

/// 🔗 말동이 백엔드 베이스 URL
/// 예: http://10.0.2.2:8000 (에뮬레이터) / http://192.168.x.x:8000 (실기기)
const String baseUrl = "http://10.0.2.2:8000";

/// 전역 TTS 플레이어 (한 개만 만들어서 재사용)
final AudioPlayer maldongTtsPlayer = AudioPlayer();

/// 🎙 음성 + 프레임을 백엔드로 보내고,
///    LLM 답변 + TTS 오디오를 받아서 바로 재생까지 하는 함수
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
    throw Exception(
        "말동이 서버 오류: ${response.statusCode} / ${response.body}");
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
