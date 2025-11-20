import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 🌐 웹 여부 체크
import 'package:camera/camera.dart';
import 'package:record/record.dart'; // 🔊 record v6.x
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart'; // global cameras 사용
import '../maldong_avatar.dart';

class VideoCallScreen extends StatefulWidget {
  final VoidCallback onEndCall;
  final Widget avatar;

  const VideoCallScreen({
    super.key,
    required this.onEndCall,
    required this.avatar,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int _seconds = 0;
  Timer? _timer;

  // ✅ 카메라 관련 필드
  CameraController? _cameraController;
  bool _isCameraOn = false;

  // 🔊 record v6.x → AudioRecorder 사용
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

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

    // 🎲 랜덤 배경 선택
    _selectedBackground = _backgrounds[Random().nextInt(_backgrounds.length)];

    // ⏱ 통화 타이머 시작
    _startTimer();

    // 🔊 모바일/데스크탑 앱에서만 녹음 자동 시작 (웹에서는 스킵)
    if (!kIsWeb) {
      _startRecordingAutomatically();
    } else {
      debugPrint('🌐 Web: 녹음 자동 시작 안 함');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _stopRecording(); // 🔊 화면 닫힐 때 녹음 종료 (실제로 녹음 중일 때만)
    super.dispose();
  }

  // =========================
  // ⏱ 타이머 관련
  // =========================
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds++;
      });
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // =========================
  // 📷 카메라 관련
  // =========================
  Future<void> _initCamera() async {
    // 🌐 웹에서는 카메라 사용 안 함 → 그냥 안내만
    if (kIsWeb) {
      debugPrint('🌐 Web: 카메라 초기화 스킵');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이 환경에서는 카메라를 사용할 수 없어요.')),
        );
      }
      return;
    }

    // 전역 카메라 리스트가 비어있으면 그냥 스킵
    if (cameras.isEmpty) {
      debugPrint('🚫 사용 가능한 카메라가 없습니다 (cameras 리스트 비어 있음)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용 가능한 카메라가 없습니다.')),
        );
      }
      return;
    }

    try {
      final camera = cameras.first;
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false, // 🔊 오디오는 record에서 처리
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraOn = true;
      });
    } catch (e) {
      debugPrint('📷 카메라 초기화 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라를 초기화할 수 없어요.')),
      );
    }
  }

  Future<void> _toggleCamera() async {
    // 🌐 웹에서는 카메라 토글도 막기
    if (kIsWeb) {
      debugPrint('🌐 Web: 카메라 토글 동작 안 함');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('웹 환경에서는 카메라 기능을 사용하지 않아요.')),
      );
      return;
    }

    if (_isCameraOn) {
      await _cameraController?.dispose();
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _isCameraOn = false;
      });
    } else {
      await _initCamera();
    }
  }

  // =========================
  // 🎤 오디오 녹음 관련
  // =========================

  // 통화 들어올 때 자동 녹음 시작 (모바일/데스크탑용)
  Future<void> _startRecordingAutomatically() async {
    // 웹은 녹음 스킵
    if (kIsWeb) {
      debugPrint('🌐 Web: 녹음 스킵');
      return;
    }

    // 권한 요청
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('❌ 마이크 권한이 없어 녹음을 시작할 수 없음');
      return;
    }

    await _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      // record v6.x 권한 체크
      final hasPerm = await _audioRecorder.hasPermission();
      if (!hasPerm) {
        debugPrint('❌ Record 패키지에서 녹음 권한 확인 실패');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/call_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      _recordingPath = path;

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      debugPrint('🎤 녹음 시작됨 → $path');
    } catch (e) {
      debugPrint('녹음 시작 오류: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final isRec = await _audioRecorder.isRecording();
      if (isRec) {
        final path = await _audioRecorder.stop();
        debugPrint('🛑 녹음 종료됨 → 저장 위치: $path');
      }
    } catch (e) {
      debugPrint('녹음 종료 오류: $e');
    }
  }

  // =========================
  // 🧱 UI
  // =========================

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

                  // 1) 🔹 가운데 3D 아바타 (widget.avatar 사용)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 0.9,
                      child: widget.avatar,
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
                                _formatTime(_seconds),
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
                    child: SizedBox(
                      width: 200,
                      height: 280,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _isCameraOn &&
                                _cameraController != null &&
                                _cameraController!.value.isInitialized
                            ? CameraPreview(_cameraController!)
                            : GestureDetector(
                                onTap: _toggleCamera,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFFCA28),
                                        Color(0xFFFF7043),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.camera_alt,
                                        color: Colors.white70,
                                        size: 40,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '카메라 켜기',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
                            // TODO: 통화 중 채팅 기능
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('채팅 기능은 준비 중입니다.')),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () {
                            debugPrint('[CALL] 통화 종료 버튼 클릭');
                            _stopRecording();
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
                          icon: _isCameraOn
                              ? Icons.videocam_off
                              : Icons.videocam,
                          onTap: _toggleCamera,
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
