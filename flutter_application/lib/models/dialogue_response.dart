// lib/models/dialogue_response.dart

class DialogueResponse {
  final int? userId;
  final String userText;
  final String emotion;
  final double confidence;
  final double riskScore;
  final String llmReply;
  final String ttsAudioBase64;
  final String analysisId;
  final String timestamp;

  DialogueResponse({
    required this.userId,
    required this.userText,
    required this.emotion,
    required this.confidence,
    required this.riskScore,
    required this.llmReply,
    required this.ttsAudioBase64,
    required this.analysisId,
    required this.timestamp,
  });

  factory DialogueResponse.fromJson(Map<String, dynamic> json) {
    return DialogueResponse(
      userId: json['user_id'],
      userText: json['user_text'] ?? "",
      emotion: json['emotion'] ?? "",
      confidence: (json['confidence'] as num).toDouble(),
      riskScore: (json['risk_score'] as num).toDouble(),
      llmReply: json['llm_reply'] ?? "",
      ttsAudioBase64: json['tts_audio_base64'] ?? "",
      analysisId: json['analysis_id'] ?? "",
      timestamp: json['timestamp'] ?? "",
    );
  }
}
