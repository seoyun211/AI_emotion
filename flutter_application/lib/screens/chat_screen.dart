import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

// 통화 세션 관리를 위한 임포트
import '../models/session.dart'; 
import '../services/dialogue_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class MaldongChatOverlay extends StatefulWidget {
  const MaldongChatOverlay({super.key});

  @override
  State<MaldongChatOverlay> createState() => _MaldongChatOverlayState();
}

class _MaldongChatOverlayState extends State<MaldongChatOverlay> {
  final List<ChatMessage> _messages = [];
  final String baseUrl = "http://localhost:8000";

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  bool _isProcessing = false; 
  String _userSpeech = ""; 
  Timer? _silenceTimer;

  // 세션 관리 상태 변수
  int? _currentSessionId;
  String _fullTranscript = ''; 
  final int _userId = 1; // ⭐ 실제 로그인된 userId로 대체 필요

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startSessionOnServer(); // 세션 시작 호출
  }
  
  // ===================================
  // 세션 관리 로직 (DB 저장)
  // ===================================

  // 세션 시작 (POST /session/start)
  Future<void> _startSessionOnServer() async {
    try {
      final session = await startSession(userId: _userId);
      setState(() {
        _currentSessionId = session.sessionId;
      });
      print('✅ Session Started. ID: $_currentSessionId');
    } catch (e) {
      print('❌ Failed to start session: $e');
    }
  }

  // 세션 종료 (POST /session/end)
  Future<void> _endSessionOnServer() async {
    if (_currentSessionId == null) return;

    try {
      await endSession(
        sessionId: _currentSessionId!,
        userId: _userId,
        fullTranscript: _fullTranscript, // 누적된 전체 녹취록 전송
      );
      print('✅ Session Ended and Transcript Saved. Full Transcript Length: ${_fullTranscript.length}');
      _currentSessionId = null; 
    } catch (e) {
      print('❌ Failed to end session: $e');
    }
  }

  // ===================================
  // 기존 서비스 로직 및 STT 누적
  // ===================================

  Future<void> _initializeServices() async {
    await _stt.initialize();
    await _tts.setLanguage("ko-KR");
    await _tts.setSpeechRate(0.8);

    Future.delayed(const Duration(milliseconds: 500), () {
      _sayWelcomeMessage();
    });
  }

  Future<void> _sayWelcomeMessage() async {
    String welcome = "안녕하세요 저는 말동이입니다. 오늘 하루는 어땠나요?";
    _addMessage(welcome, false);
    await _tts.speak(welcome);
    _startListening();
    
    // 말동이의 초기 발화도 녹취록에 추가
    if (_fullTranscript.isNotEmpty) {
        _fullTranscript += '\n'; 
    }
    _fullTranscript += "말동이: $welcome";
  }

  void _startListening() async {
    bool available = await _stt.initialize();
    if (!available || _isProcessing || _stt.isListening) return;

    setState(() => _isListening = true);
    
    await _stt.listen(
      onResult: (result) {
        if (!_isProcessing) {
          setState(() {
            _userSpeech = result.recognizedWords;
            _resetSilenceTimer();
          });
        }
      },
      localeId: "ko_KR",
      listenMode: ListenMode.dictation,
      cancelOnError: true,
    );
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 3), () {
      if (_userSpeech.isNotEmpty && !_isProcessing) {
        _handleMaldongResponse();
      }
    });
  }

  Future<void> _handleMaldongResponse() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isListening = false;
    });

    _silenceTimer?.cancel();
    await _stt.stop();

    String capturedSpeech = _userSpeech;
    setState(() => _userSpeech = ""); 

    // 사용자 발화 텍스트 누적
    if (_fullTranscript.isNotEmpty) {
        _fullTranscript += '\n'; 
    }
    _fullTranscript += "사용자: $capturedSpeech"; 
    
    _addMessage(capturedSpeech, true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/v1/dialogue/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": capturedSpeech}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String maldongAnswer = data['answer'];
        
        // 말동이 답변도 녹취록에 누적
        _fullTranscript += "\n말동이: $maldongAnswer"; 

        _addMessage(maldongAnswer, false);

        await _tts.speak(maldongAnswer);
        
        await Future.delayed(const Duration(milliseconds: 500)); 
      } else {
        _addMessage("서버 응답 오류가 발생했어요.", false);
      }
    } catch (e) {
      _addMessage("잠시 연결이 불안정해요.", false);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _startListening();
      }
    }
  }

  void _addMessage(String text, bool isUser) {
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: text, isUser: isUser));
      });
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _stt.stop();
    _tts.stop();
    
    // 위젯이 닫힐 때 통화 종료 기록
    _endSessionOnServer(); 

    super.dispose();
  }
  
  // ===================================
  // UI 빌드 로직
  // ===================================

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
          
          if (_userSpeech.isNotEmpty && !_isProcessing)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _userSpeech,
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
                Icon(
                  _isListening && !_isProcessing ? Icons.mic : Icons.mic_off,
                  size: 14,
                  color: _isListening && !_isProcessing ? Colors.greenAccent : Colors.white24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isProcessing ? "말동이가 생각 중" : (_isListening ? "말동이가 듣는 중" : "잠시 대기 중"),
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
} // <--- _MaldongChatOverlayState 클래스 닫기

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