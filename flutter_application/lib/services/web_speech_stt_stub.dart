// lib/services/web_speech_stt_stub.dart
import 'package:flutter/foundation.dart' show VoidCallback;

typedef OnText = void Function(String text, bool isFinal);

class WebSpeechStt {
  bool get isAvailable => false;
  bool get isListening => false;

  VoidCallback? onStart;
  VoidCallback? onEnd;
  void Function(String error)? onError;
  OnText? onText;

  Future<void> init({String lang = "ko-KR"}) async {}
  void start() {}
  void stop() {}
  void dispose() {}
}
