import 'package:flutter/material.dart';

class GuardianAnalysisScreen extends StatelessWidget {
  final int guardianUserId;
  final String accessToken;
  final VoidCallback? onOpenSettings; // ✅ Nullable 로 변경

  const GuardianAnalysisScreen({
    super.key,
    required this.guardianUserId,
    required this.accessToken,
    this.onOpenSettings, // ✅ 이제 에러 안 남
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 분석'),
        actions: [
          if (onOpenSettings != null) // ✅ null 체크 후 버튼 표시
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: onOpenSettings,
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Guardian Analysis Screen (상세 분석 화면)',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text('guardianUserId: $guardianUserId'),
            Text('accessToken: $accessToken'),
          ],
        ),
      ),
    );
  }
}
