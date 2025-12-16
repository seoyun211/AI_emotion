import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:audioplayers/audioplayers.dart';

const String baseUrl = "http://127.0.0.1:8000";

// ✅ /api/v1은 공통 prefix로만 사용 (dialogue, web 등 하위에서 나눔)
const String apiPrefix = "/api/v1";

final AudioPlayer maldongTtsPlayer = AudioPlayer();

// =========================================================
// ✅ 통화 1번 = 감정 1개 저장 정책용 전역 상태(마지막 결과 저장)
// =========================================================
int? currentSessionId;

String lastFinalEmotion = "기쁨";
double lastRiskScore = 0.0;

String lastTranscript = "";
List<String> transcriptLines = [];

// =========================================================
// ✅ 서버 응답 키가 달라도 안전하게 뽑아오는 헬퍼
// =========================================================
String _pickEmotion(Map<String, dynamic> data) {
  final e = (data["final_emotion"] ??
          data["final_result"] ??
          data["emotion"] ??
          data["top_emotion"] ??
          "")
      .toString()
      .trim();
  return e.isEmpty ? "기쁨" : e;
}

double _pickRisk(Map<String, dynamic> data) {
  final rs = data["risk_score"];
  if (rs is num) return rs.toDouble();
  return 0.0;
}

String _pickReply(Map<String, dynamic> data) {
  return (data["llm_reply"] ?? data["reply"] ?? data["response"] ?? "").toString();
}

// =========================================================
// ✅ 감정분석(Web) + 프레임 업로드  (서버: /api/v1/web/analyze)
// =========================================================
Future<Map<String, dynamic>> sendToMaldongWeb({
  required String text,
  required List<Uint8List> frames,
  required int userId,
}) async {
  // ✅ 여기만 바뀜: /dialogue/web -> /web/analyze
  final uri = Uri.parse("$baseUrl$apiPrefix/web/analyze");

  // ignore: avoid_print
  print("📌 sendToMaldongWeb => $uri, frames=${frames.length}, textLen=${text.length}");

  final request = http.MultipartRequest("POST", uri);

  // ✅ 서버(web_analyze.py)에서 Form(...) 으로 받는 필드명과 동일해야 함
  request.fields["text"] = text;
  request.fields["user_id"] = userId.toString();

  for (int i = 0; i < frames.length; i++) {
    request.files.add(
      http.MultipartFile.fromBytes(
        "frames", // ✅ 서버 파라미터 이름: frames
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

// =========================================================
// ✅ 감정분석 + (정책용) 마지막 결과/녹취 누적
// ⚠️ web_analyze는 기본적으로 llm_reply/tts_audio_base64가 없음(없어도 정상)
// =========================================================
Future<Map<String, dynamic>> sendToMaldongWebAndPlayTts({
  required String text,
  required List<Uint8List> frames,
  required int userId,
}) async {
  final data =
      await sendToMaldongWeb(text: text, frames: frames, userId: userId);

  // ✅ 정책용 마지막 값 업데이트(통화 종료 시 이 1개만 저장)
  lastTranscript = text;
  lastFinalEmotion = _pickEmotion(data);
  lastRiskScore = _pickRisk(data);

  // ✅ transcript 누적(통화 종료 시 full_transcript로 저장)
  transcriptLines.add("사용자: $text");

  // ⚠️ web_analyze 응답엔 reply가 없을 수 있음(대부분 없음)
  final reply = _pickReply(data);
  if (reply.trim().isNotEmpty) transcriptLines.add("말동이: $reply");

  // ⚠️ web_analyze 응답엔 tts가 없을 수 있음(대부분 없음)
  final b64 = (data["tts_audio_base64"] ?? "").toString();
  if (b64.isNotEmpty) {
    final bytes = base64Decode(b64);
    await maldongTtsPlayer.stop();
    await maldongTtsPlayer.play(BytesSource(bytes));
  }

  // ignore: avoid_print
  print("✅ lastFinalEmotion=$lastFinalEmotion, lastRiskScore=$lastRiskScore");
  return data;
}

// =========================================================
// ✅ 세션 저장 (start/end)  (서버: /api/v1/dialogue/session/start, /end)
// =========================================================
Future<int?> startCallSession({required int userId}) async {
  final uri = Uri.parse("$baseUrl$apiPrefix/dialogue/session/start?user_id=$userId");
  final res = await http.post(uri);

  if (res.statusCode != 200) {
    throw Exception(
      "세션 시작 실패: ${res.statusCode}\n${utf8.decode(res.bodyBytes)}",
    );
  }

  final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  currentSessionId = (data["session_id"] as num?)?.toInt();

  // ✅ 시작 시 초기화(이 통화의 대표 감정/점수/녹취)
  lastFinalEmotion = "기쁨";
  lastRiskScore = 0.0;
  lastTranscript = "";
  transcriptLines = [];

  return currentSessionId;
}

Future<Map<String, dynamic>> endCallSession({
  required int sessionId,
  required int userId,
  String? fullTranscriptOverride,
  String? finalEmotionOverride,
  double? riskScoreOverride,
}) async {
  final uri = Uri.parse("$baseUrl$apiPrefix/dialogue/session/end");

  final fullTranscript =
      (fullTranscriptOverride != null && fullTranscriptOverride.trim().isNotEmpty)
          ? fullTranscriptOverride.trim()
          : (transcriptLines.isNotEmpty
              ? transcriptLines.join("\n")
              : (lastTranscript.isNotEmpty ? lastTranscript : "..."));

  final finalEmotion =
      (finalEmotionOverride != null && finalEmotionOverride.trim().isNotEmpty)
          ? finalEmotionOverride.trim()
          : lastFinalEmotion;

  final riskScore = riskScoreOverride ?? lastRiskScore;

  final res = await http.post(
    uri,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "session_id": sessionId,
      "user_id": userId,
      "full_transcript": fullTranscript,
      "final_emotion": finalEmotion,
      "risk_score": riskScore,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception(
      "세션 종료 실패: ${res.statusCode}\n${utf8.decode(res.bodyBytes)}",
    );
  }

  currentSessionId = null;
  return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
}
