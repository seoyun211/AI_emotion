import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 🔍 웹 여부 체크
import 'package:camera/camera.dart';
import 'package:record/record.dart'; // 🔊 녹음 패키지 (v6.x → AudioRecorder)
import 'package:path_provider/path_provider.dart'; // 🔊 저장 경로 (모바일/데스크탑용)
import 'package:permission_handler/permission_handler.dart'; // 🔊 마이크 권한

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

  // 🔊 녹음 관련 필드 (record v6.x → AudioRecorder 사용)
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

    // 🎲 통화 화면 들어올 때 배경 한 개 랜덤 선택
    _selectedBackground = _backgrounds[Random().nextInt(_backgrounds.length)];

    _startTimer();

    // 🔊 통화 시작과 동시에 자동 녹음 시작 (📱 모바일/데스크탑만, Web은 스킵)
    _startRecordingAutomatically();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _stopRecording(); // 🔊 화면 닫힐 때 녹음 종료
    super.dispose();
  }

  // 통화 시간 타이머
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

  // ✅ 카메라 초기화
  Future<void> _initCamera() async {
    // 🌐 웹에서는 카메라 플러그인 쓰지 않음
    if (kIsWeb) {
      debugPrint('🌐 Web: 카메라 초기화 스킵');
      return;
    }

    if (cameras.isEmpty) {
      debugPrint('🚫 사용 가능한 카메라 없음');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용할 수 있는 카메라가 없어요.')),
        );
      }
      return;
    }

    try {
      final camera = cameras.first; // 필요하면 전/후면 골라서 사용
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false, // 🔊 오디오는 record 패키지가 담당
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraOn = true;
      });
    } catch (e) {
      debugPrint('📷 카메라 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카메라를 사용할 수 없어요. (장치 없음 또는 권한 문제)'),
          ),
        );
      }
    }
  }

  // ✅ 카메라 ON/OFF 토글
  Future<void> _toggleCamera() async {
    // 🌐 웹에서는 카메라 미리보기 지원 X
    if (kIsWeb) {
      debugPrint('🌐 Web: 카메라 버튼 눌림 (지원 안 함)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('웹에서는 카메라 미리보기를 지원하지 않아요.')),
        );
      }
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

  // 🔊 통화 들어올 때 자동 녹음 시작
  Future<void> _startRecordingAutomatically() async {
    // 👉 웹(Chrome)에서는 녹음/로컬 파일 경로 사용 안 함
    if (kIsWeb) {
      debugPrint('🌐 Web 환경에서는 오디오 녹음을 수행하지 않습니다.');
      return;
    }

    // 1) 권한 요청
    final status = await Permission.microphone.request();

    if (!status.isGranted) {
      debugPrint("❌ 마이크 권한이 없어 녹음을 시작할 수 없음");
      return;
    }

    // 2) 녹음 시작
    await _startRecording();
  }

  // 🔊 실제 녹음 시작
  Future<void> _startRecording() async {
    try {
      if (kIsWeb) {
        debugPrint('🌐 Web에서는 _startRecording()가 동작하지 않도록 막혀 있습니다.');
        return;
      }

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint("❌ Record 패키지 권한 없음");
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/call_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      _recordingPath = path;

      // record v6.x API
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      debugPrint("🎤 녹음 시작됨 → $path");
    } catch (e) {
      debugPrint("녹음 시작 오류: $e");
    }
  }

  // 🔊 녹음 종료
  Future<void> _stopRecording() async {
    try {
      // 웹에서는 플러그인 자체가 없을 수 있으니 바로 리턴
      if (kIsWeb) {
        return;
      }

      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        debugPrint("🛑 녹음 종료됨 → 저장됨: $path");
      }
    } catch (e) {
      debugPrint("녹음 종료 오류: $e");
    }
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

                  // 1) 🔹 가운데 3D 아바타 (widget.avatar 사용)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 0.9, // 필요하면 크기 조절
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
                            ? CameraPreview(_cameraController!) // ✅ 실제 카메라 미리보기
                            : GestureDetector(
                                onTap: _toggleCamera, // 탭해서 켜기
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
                            // TODO: 통화 중 채팅
                          },
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () {
                            debugPrint('[CALL] 통화 종료 버튼 클릭');
                            _stopRecording(); // 🔊 통화 종료할 때 녹음도 같이 종료
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
                              : Icons.videocam, // ✅ 상태에 따라 아이콘 변경
                          onTap: _toggleCamera, // ✅ 아래 버튼으로도 ON/OFF
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
