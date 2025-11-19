import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 샘플 통화 기록 데이터
    final callHistory = [
      CallRecord(
        date: DateTime.now().subtract(const Duration(hours: 2)),
        duration: const Duration(minutes: 15, seconds: 32),
        type: CallType.video,
      ),
      CallRecord(
        date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        duration: const Duration(minutes: 8, seconds: 45),
        type: CallType.video,
      ),
      CallRecord(
        date: DateTime.now().subtract(const Duration(days: 2)),
        duration: const Duration(minutes: 22, seconds: 10),
        type: CallType.video,
      ),
      CallRecord(
        date: DateTime.now().subtract(const Duration(days: 3)),
        duration: const Duration(minutes: 12, seconds: 5),
        type: CallType.video,
      ),
      CallRecord(
        date: DateTime.now().subtract(const Duration(days: 5)),
        duration: const Duration(minutes: 18, seconds: 50),
        type: CallType.video,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '통화기록',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '말동이와의 모든 통화 내역',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 통화 기록 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: callHistory.length,
                itemBuilder: (context, index) {
                  final call = callHistory[index];
                  return _CallHistoryItem(call: call);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallHistoryItem extends StatelessWidget {
  final CallRecord call;

  const _CallHistoryItem({required this.call});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM월 dd일 (E)', 'ko_KR');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCallTypeColor(call.type),
                    _getCallTypeColor(call.type).withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCallTypeIcon(call.type),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '말동이',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${dateFormat.format(call.date)} ${timeFormat.format(call.date)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCallTypeColor(call.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      call.type == CallType.video ? '영상통화' : '음성통화',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCallTypeColor(call.type),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 통화 시간
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(call.duration),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCallTypeIcon(CallType type) {
    switch (type) {
      case CallType.video:
        return Icons.videocam;
      case CallType.audio:
        return Icons.phone;
    }
  }

  Color _getCallTypeColor(CallType type) {
    switch (type) {
      case CallType.video:
        return const Color(0xFFFF9800);
      case CallType.audio:
        return const Color(0xFFFFB74D);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}분 ${seconds}초';
  }
}

// 통화 기록 모델
class CallRecord {
  final DateTime date;
  final Duration duration;
  final CallType type;

  CallRecord({
    required this.date,
    required this.duration,
    required this.type,
  });
}

enum CallType {
  video,
  audio,
}