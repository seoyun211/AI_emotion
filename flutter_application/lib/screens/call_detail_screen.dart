// lib/screens/call_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// CallRecord 모델이 다른 파일(call_history_screen.dart)에 정의되어 있으므로 임포트합니다.
import 'call_history_screen.dart'; 

class CallDetailScreen extends StatelessWidget {
  // CallHistoryScreen에서 전달받을 CallRecord 객체
  final CallRecord callRecord;

  const CallDetailScreen({super.key, required this.callRecord});

  // 통화 시간 포맷 함수 (필요하다면)
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}분 ${seconds}초';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko_KR');
    
    // 녹취록 내용. 내용이 없으면 기본 메시지를 표시합니다.
    final String transcript = callRecord.fullTranscript ?? '녹취록이 저장되지 않았거나 데이터에 오류가 있습니다.';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(
          // 통화 시작 시간으로 제목을 설정
          '통화 상세 기록: ${dateFormat.format(callRecord.date)}',
          style: const TextStyle(color: Color(0xFF5D4037), fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 통화 지속 시간 표시
            Text(
              callRecord.duration != null ? 
                '통화 시간: ${_formatDuration(callRecord.duration!)}' : 
                '통화 시간: 기록 없음',
              style: const TextStyle(fontSize: 16, color: Color(0xFF8D6E63)),
            ),
            const SizedBox(height: 20),
            
            // 녹취록 헤더
            const Text(
              '대화 녹취록',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 16),
            
            // 녹취록 본문
            Container(
              width: double.infinity, // 너비를 최대로
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.5)),
              ),
              child: Text(
                transcript,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF3E2723),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}