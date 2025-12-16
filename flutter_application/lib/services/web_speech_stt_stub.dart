// lib/services/web_speech_stt_stub.dart
typedef OnText = void Function(String text, bool isFinal);

class WebSpeechStt {
  bool get isAvailable => false;
  bool get isListening => false;

  void Function()? onStart;
  void Function()? onEnd;
  void Function(String error)? onError;
  OnText? onText;

  Future<void> init({String lang = "ko-KR"}) async {}
  void start() {}
  void stop() {}
  void dispose() {}
}
