import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../maldong_avatar.dart';

// ✅ 네 Ready Player Me 아바타 GLB URL (여자)
const String kFemaleAvatarUrl =
    'https://models.readyplayer.me/690d8484132e61458cf8e667.glb';

// 필요하면 남자도 나중에 쓰려고 미리 빼둬도 됨
const String kMaleAvatarUrl =
    'https://models.readyplayer.me/690d81ec37697c47c8a85f69.glb';

class VideoCallScreen extends StatefulWidget {
  final VoidCallback onEndCall;

  const VideoCallScreen({
    super.key,
    required this.onEndCall,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int _seconds = 0;
  Timer? _timer;

  final List<String> _backgrounds = [
    'assets/background/cafe.png',
    'assets/background/office.png',
    'assets/background/bed.png',
    'assets/background/home.png',
    'assets/background/beach.png',
    'assets/background/park.png',
  ];

  late String _selectedBackground;

  @override
  void initState() {
    super.initState();
    // 🎲 통화 화면 들어올 때 배경 한 개 랜덤 선택
    final random = Random();
    _selectedBackground = _backgrounds[random.nextInt(_backgrounds.length)];

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds += 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final m = mins.toString().padLeft(2, '0');
    final s = secs.toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 0) 🔹 랜덤 배경 이미지
                  Positioned.fill(
                    child: Image.asset(
                      _selectedBackground,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 1) 🔹 아바타를 전체 화면에 + 살짝 확대
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 1.15, // 👉 아바타 조금 키운 부분
                      child: const MaldongAvatar(
                        avatarUrl: kFemaleAvatarUrl,
                      ),
                    ),
                  ),

                  // 2) 상단 왼쪽: 통화 중 + 시간 표시
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '통화 중',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTime(_seconds), // mm:ss
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3) 상단 오른쪽: 내 캠 미리보기 박스
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 200,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFCA28), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4) 하단 컨트롤 버튼들
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circleButton(
                          icon: Icons.chat_bubble_outline,
                          onTap: () {
                            // TODO: 통화 중 채팅
                          },
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () {
                            widget.onEndCall();
                          },
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        _circleButton(
                          icon: Icons.videocam,
                          onTap: () {
                            // TODO: 카메라 ON/OFF
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
