import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class MaldongChatOverlay extends StatefulWidget {
  final String? lastVoicePath; // 부모로부터 전달받은 녹음 파일 경로

  const MaldongChatOverlay({super.key, this.lastVoicePath});

  @override
  State<MaldongChatOverlay> createState() => _MaldongChatOverlayState();
}

class _MaldongChatOverlayState extends State<MaldongChatOverlay> {
  final List<ChatMessage> _messages = [];
  final String baseUrl = "http://192.168.x.x:8000"; // 실제 서버 IP

  // 서버 통신 함수 (이전 코드와 동일)
  Future<void> sendVoice(String filePath) async {
    // ... (이전의 sendVoiceToMaldong 로직)
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      bottom: 100,
      width: 280,
      height: 350,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListView.builder(
          reverse: true,
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msg = _messages[_messages.length - 1 - index];
            return ChatBubble(msg: msg); // 별도 위젯으로 분리 권장
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
      // 사용자는 오른쪽, 말동이는 왼쪽 정렬
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          // 사용자는 노란색, 말동이는 흰색 바탕
          color: msg.isUser 
              ? Colors.yellow.withOpacity(0.9) 
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(msg.isUser ? 12 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}