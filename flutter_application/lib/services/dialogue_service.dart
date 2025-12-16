import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ pubspec에 http_parser 추가 필요
import 'package:audioplayers/audioplayers.dart';

/// 웹에서는 localhost OK
const String baseUrl = "http://localhost:8000";

/// ✅ 백엔드 router = APIRouter(prefix="/dialogue") 이라서
/// /dialogue/web 로 호출
const String apiPrefix = "/dialogue";

/// ✅ TTS 플레이어 (웹에서도 재생됨)
final AudioPlayer maldongTtsPlayer = AudioPlayer();

/// ===============================
/// ✅ Flutter Web 전용
/// 텍스트 + 프레임(5장) → /dialogue/web
/// ===============================
Future<Map<String, dynamic>> sendToMaldongWeb({
  required String text,
  required List<Uint8List> frames,
  required int userId,
}) async {
  final uri = Uri.parse("$baseUrl$apiPrefix/web");
  final request = http.MultipartRequest("POST", uri);

  // 1) text + user_id
  request.fields["text"] = text;
  request.fields["user_id"] = userId.toString();

  // 2) frames
  for (int i = 0; i < frames.length; i++) {
    request.files.add(
      http.MultipartFile.fromBytes(
        "frames",
        frames[i],
        filename: "frame_$i.jpg",
        contentType: MediaType("image", "jpeg"),
      ),
    );
  }

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode != 200) {
    throw Exception(
      "웹 감정분석 실패: ${response.statusCode}\n${utf8.decode(response.bodyBytes)}",
    );
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}

/// ===============================
/// ✅ Web: 분석 요청 + TTS 재생까지
/// (VideoCallScreen에서 이걸 호출하면 됨)
/// ===============================
Future<Map<String, dynamic>> sendToMaldongWebAndPlayTts({
  required String text,
  required List<Uint8List> frames,
  required int userId,
}) async {
  final data = await sendToMaldongWeb(text: text, frames: frames, userId: userId);

  final String b64 = (data["tts_audio_base64"] ?? "").toString();
  if (b64.isNotEmpty) {
    final bytes = base64Decode(b64);
    await maldongTtsPlayer.stop();
    await maldongTtsPlayer.play(BytesSource(bytes));
  }

  return data;
}
