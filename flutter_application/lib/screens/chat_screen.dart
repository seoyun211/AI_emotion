import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/web_speech_stt.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

// ✅ 외부(VideoCallScreen)에서 말동이 메시지/타이핑 상태를 제어할 컨트롤러
class MaldongChatController {
  void Function(String text)? _addBot;
  void Function(bool on)? _setTyping;

  void _bind(void Function(String) addBotFn, void Function(bool) typingFn) {
    _addBot = addBotFn;
    _setTyping = typingFn;
  }

  void _unbind() {
    _addBot = null;
    _setTyping = null;
  }

  void addBotMessage(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _addBot?.call(t);
  }

  void setTyping(bool on) {
    _setTyping?.call(on);
  }
}

class MaldongChatOverlay extends StatefulWidget {
  final ValueChanged<String>? onFinalText;
  final MaldongChatController? controller;

  const MaldongChatOverlay({
    super.key,
    this.onFinalText,
    this.controller,
  });

  @override
  State<MaldongChatOverlay> createState() => _MaldongChatOverlayState();
}

class _MaldongChatOverlayState extends State<MaldongChatOverlay> {
  final List<ChatMessage> _messages = [];

  // ✅ 자동 스크롤
  final ScrollController _scrollCtrl = ScrollController();

  bool _isProcessing = false;

  final WebSpeechStt _webStt = WebSpeechStt();
  bool _sttReady = false;
  bool _isListening = false;

  String _liveSpeech = "";
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _sayWelcomeMessage();
    _initWebStt();

    // ✅ 부모에서 bot message/typing 제어 가능하게 bind
    widget.controller?._bind(
      (text) => _addMessage(text, false),
      (on) {
        if (!mounted) return;
        setState(() => _isProcessing = on);
      },
    );
  }

  @override
  void dispose() {
    widget.controller?._unbind();
    _scrollCtrl.dispose();
    _silenceTimer?.cancel();
    _webStt.dispose();
    super.dispose();
  }

  Future<void> _sayWelcomeMessage() async {
    const welcome = "안녕하세요 저는 말동이입니다. 오늘 하루는 어땠나요?";
    _addMessage(welcome, false);
  }

  Future<void> _initWebStt() async {
    if (!kIsWeb) return;

    await _webStt.init(lang: "ko-KR");
    if (!_webStt.isAvailable) {
      if (!mounted) return;
      setState(() => _sttReady = false);
      return;
    }

    _webStt.onStart = () {
      if (!mounted) return;
      setState(() => _isListening = true);
    };

    _webStt.onEnd = () {
      if (!mounted) return;
      setState(() => _isListening = false);
    };

    // ✅ no-speech 등 에러 시: 타이핑/상태 강제 해제
    _webStt.onError = (err) {
      if (!mounted) return;

      _silenceTimer?.cancel();
      setState(() {
        _isListening = false;
        _isProcessing = false;
        _liveSpeech = "";
      });

      // ignore: avoid_print
      print("Web STT error: $err");

      if (err.toString().contains("no-speech")) {
        _addMessage("말이 잘 안 들렸어요. 마이크를 확인하고 조금 크게 말씀해 주세요!", false);
      } else {
        _addMessage("마이크 인식에 문제가 있어요. 브라우저 마이크 권한을 확인해 주세요!", false);
      }
    };

    _webStt.onText = (text, isFinal) {
      if (!mounted) return;

      setState(() => _liveSpeech = text);
      _resetSilenceTimer();

      if (isFinal) _commitFinalSpeech(text);
    };

    if (!mounted) return;
    setState(() => _sttReady = true);
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(milliseconds: 900), () {
      if (_liveSpeech.trim().isNotEmpty) {
        _commitFinalSpeech(_liveSpeech);
      }
    });
  }

  Future<void> _commitFinalSpeech(String finalText) async {
    final trimmed = finalText.trim();
    if (trimmed.isEmpty) return;

    _silenceTimer?.cancel();

    // ✅ 사용자 말풍선 즉시 표시
    _addMessage(trimmed, true);

    // ✅ 감정분석/LLM 호출은 VideoCallScreen에서 처리
    widget.onFinalText?.call(trimmed);

    // ✅ Overlay는 서버 기다리지 않음 (타이핑은 부모가 setTyping으로 제어)
    if (mounted) {
      setState(() {
        _liveSpeech = "";
      });
    }
  }

  void _toggleListening() {
    if (!kIsWeb || !_sttReady) return;
    if (_isListening) {
      _webStt.stop();
    } else {
      _webStt.start();
    }
  }

  void _addMessage(String text, bool isUser) {
    if (!mounted) return;
    setState(() => _messages.add(ChatMessage(text: text, isUser: isUser)));

    // ✅ reverse=true라 minScrollExtent로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.minScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      bottom: 220,
      width: 260,
      height: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(8),
                reverse: true,
                itemCount: _messages.length + (_isProcessing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isProcessing && index == 0) return const TypingBubble();
                  final msgIndex = _isProcessing ? index - 1 : index;
                  final msg = _messages[_messages.length - 1 - msgIndex];
                  return ChatBubble(msg: msg);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_liveSpeech.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _liveSpeech,
                style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleListening,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    size: 16,
                    color: _isListening ? Colors.greenAccent : Colors.white24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isProcessing
                      ? "말동이가 생각 중"
                      : (_sttReady ? (_isListening ? "듣는 중" : "마이크 눌러서 말하기") : "웹 STT 사용 불가"),
                  style: TextStyle(
                    fontSize: 11,
                    color: _isListening && !_isProcessing ? Colors.greenAccent : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});
  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat();
    _dotCount = IntTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedBuilder(
          animation: _dotCount,
          builder: (context, child) {
            return Text(
              "말동이가 생각 중${'.' * (_dotCount.value + 1)}",
              style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const ChatBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.yellow.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(msg.text, style: const TextStyle(color: Colors.black87, fontSize: 13)),
      ),
    );
  }
}
