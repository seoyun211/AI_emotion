import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:audioplayers/audioplayers.dart';

const String baseUrl = "http://localhost:8000";

// ✅ chat_screen이 쓰는 것과 똑같이!
const String apiPrefix = "/api/v1/dialogue";

final AudioPlayer maldongTtsPlayer = AudioPlayer();

Future<Map<String, dynamic>> sendToMaldongWeb({
  required String text,
  required List<Uint8List> frames,
  required int userId,
}) async {
  final uri = Uri.parse("$baseUrl$apiPrefix/web");

  // ✅ 디버그: 지금 정확히 어디로 쏘는지 로그 찍어봐
  // ignore: avoid_print
  print("📌 sendToMaldongWeb => $uri, frames=${frames.length}, textLen=${text.length}");

  final request = http.MultipartRequest("POST", uri);

  request.fields["text"] = text;
  request.fields["user_id"] = userId.toString();

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

Future<Map<String, dynamic>> sendToMaldongWebAndPlayTts({
  required String text,
  required List<Uint8List> frames,
  required int userId,
}) async {
  final data = await sendToMaldongWeb(text: text, frames: frames, userId: userId);

  final b64 = (data["tts_audio_base64"] ?? "").toString();
  if (b64.isNotEmpty) {
    final bytes = base64Decode(b64);
    await maldongTtsPlayer.stop();
    await maldongTtsPlayer.play(BytesSource(bytes));
  }

  return data;
}
