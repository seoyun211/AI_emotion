import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  // 실제 서버 PC의 IP 주소로 수정 필요
  final String baseUrl = "http://192.168.x.x:8000"; 

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      bottom: 140,
      width: 260,
      height: 320,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          reverse: true,
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msg = _messages[_messages.length - 1 - index];
            return ChatBubble(msg: msg);
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
        child: Text(msg.text, style: const TextStyle(color: Colors.black87, fontSize: 14)),
      ),
    );
  }
}