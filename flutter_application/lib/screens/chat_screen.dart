import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/web_speech_stt_web.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class MaldongChatOverlay extends StatefulWidget {
  final ValueChanged<String>? onFinalText;

  const MaldongChatOverlay({
    super.key,
    this.onFinalText,
  });

  @override
  State<MaldongChatOverlay> createState() => _MaldongChatOverlayState();
}

class _MaldongChatOverlayState extends State<MaldongChatOverlay> {
  final List<ChatMessage> _messages = [];
  final String baseUrl = "http://localhost:8000";

  bool _isProcessing = false;

  // ✅ 웹 STT
  final WebSpeechStt _webStt = WebSpeechStt();
  bool _sttReady = false;
  bool _isListening = false;

  String _liveSpeech = ""; // 인식 중(중간/최종) 텍스트
  Timer? _silenceTimer;

  final int _userId = 1; // ✅ 로그인 값으로 교체

  @override
  void initState() {
    super.initState();
    _sayWelcomeMessage();
    _initWebStt();
  }

  @override
  void dispose() {
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
      setState(() {
        _sttReady = false;
      });
      return;
    }

    _webStt.onStart = () => setState(() => _isListening = true);
    _webStt.onEnd = () => setState(() => _isListening = false);

    _webStt.onError = (err) {
      setState(() => _isListening = false);
      // 너무 시끄러우면 계속 떠서 스낵바는 최소화
      // ignore: avoid_print
      print("Web STT error: $err");
    };

    _webStt.onResult = (text, isFinal) {
      if (!mounted) return;

      setState(() => _liveSpeech = text);

      // 말하는 중이면 타이머 리셋
      _resetSilenceTimer();

      // final 문장이면 즉시 전송 + 콜백
      if (isFinal) {
        _commitFinalSpeech(text);
      }
    };

    setState(() {
      _sttReady = true;
    });
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(milliseconds: 900), () {
      // 0.9초 무음이면 현재 문장을 확정 처리 (UX 좋게)
      if (_liveSpeech.trim().isNotEmpty && !_isProcessing) {
        _commitFinalSpeech(_liveSpeech);
      }
    });
  }

  Future<void> _commitFinalSpeech(String finalText) async {
    final trimmed = finalText.trim();
    if (trimmed.isEmpty) return;
    if (_isProcessing) return;

    _silenceTimer?.cancel();

    setState(() {
      _isProcessing = true;
      _liveSpeech = ""; // 확정 후 비움
    });

    // ✅ 채팅창에 유저 메시지로 추가
    _addMessage(trimmed, true);

    // ✅ VideoCallScreen에 최종 텍스트 전달 (감정분석 루프가 사용)
    widget.onFinalText?.call(trimmed);

    try {
      // ✅ 웹 엔드포인트: /api/v1/dialogue/web
      final uri = Uri.parse("$baseUrl/api/v1/dialogue/web");
      final req = http.MultipartRequest("POST", uri);
      req.fields["user_id"] = _userId.toString();
      req.fields["text"] = trimmed;

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        _addMessage("서버 응답 오류가 발생했어요. (${res.statusCode})", false);
        return;
      }

      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final reply = (data["llm_reply"] ?? "…").toString();
      _addMessage(reply, false);
    } catch (e) {
      _addMessage("잠시 연결이 불안정해요. 마이크/네트워크를 확인해 주세요!", false);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _toggleListening() {
    if (!kIsWeb || !_sttReady) return;

    if (_isListening) {
      _webStt.stop();
    } else {
      // 브라우저 정책상 “사용자 클릭 이벤트”에서 start 해야 안전
      _webStt.start();
    }
  }

  void _addMessage(String text, bool isUser) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
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

          // ✅ 지금 말하고 있는 내용 표시(노란 말풍선)
          if (_liveSpeech.trim().isNotEmpty && !_isProcessing)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _liveSpeech,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),

          // ✅ 상태 바 + 마이크 버튼(웹)
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
                      : (_sttReady
                          ? (_isListening ? "듣는 중" : "마이크 눌러서 말하기")
                          : "웹 STT 사용 불가"),
                  style: TextStyle(
                    fontSize: 11,
                    color: _isListening && !_isProcessing
                        ? Colors.greenAccent
                        : Colors.white,
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

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..repeat();
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
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
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
          color: msg.isUser
              ? Colors.yellow.withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(msg.text,
            style: const TextStyle(color: Colors.black87, fontSize: 13)),
      ),
    );
  }
}
