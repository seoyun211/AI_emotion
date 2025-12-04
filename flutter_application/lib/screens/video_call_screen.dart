import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
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

  CameraController? _cameraController;
  bool _isCameraOn = false;

  // 🔥 추가된 부분: 카메라 에러 메시지 저장용
  String? _cameraErrorMessage;

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
    _selectedBackground = _backgrounds[Random().nextInt(_backgrounds.length)];
    _startTimer();
    _startRecordingAutomatically();

    // 🔥 추가된 부분: 웹이면 자동 카메라 권한 팝업 뜨도록 실행
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initCamera();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _stopRecording();
    super.dispose();
  }

  // =========================
  // 타이머
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
  // 카메라 초기화 (웹 + 모바일)
  // =========================

  Future<void> _initCamera() async {
    try {
      // 🔥 웹
      if (kIsWeb) {
        if (cameras.isEmpty) {
          setState(() => _cameraErrorMessage = "사용 가능한 카메라가 없습니다.");
          return;
        }

        final camera = cameras.first;
        final controller = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: true,
          imageFormatGroup: ImageFormatGroup.bgra8888,
        );

        await controller.initialize();

        if (!mounted) return;
        setState(() {
          _cameraController = controller;
          _isCameraOn = true;
          _cameraErrorMessage = null;
        });
        return;
      }

      // 🔥 모바일
      if (cameras.isEmpty) {
        setState(() => _cameraErrorMessage = "사용 가능한 카메라가 없습니다.");
        return;
      }

      final camera = cameras.first;
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraOn = true;
        _cameraErrorMessage = null;
      });

    } on CameraException catch (e) {
      debugPrint("📷 CameraException: ${e.code}, ${e.description}");
      setState(() {
        if (e.code == "cameraAbort") {
          _cameraErrorMessage =
              "브라우저 카메라 권한이 필요합니다.\n주소창 왼쪽 자물쇠 아이콘을 눌러 허용해주세요.";
        } else {
          _cameraErrorMessage = "카메라 오류: ${e.description ?? e.code}";
        }
        _isCameraOn = false;
        _cameraController = null;
      });

    } catch (e) {
      debugPrint("카메라 초기화 실패: $e");
      setState(() {
        _cameraErrorMessage = "카메라 초기화 중 문제가 발생했습니다.";
        _isCameraOn = false;
        _cameraController = null;
      });
    }
  }

  Future<void> _toggleCamera() async {
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
  // 오디오 녹음
  // =========================

  Future<void> _startRecordingAutomatically() async {
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
    }

    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final hasPerm = await _audioRecorder.hasPermission();
      if (!hasPerm) return;

      final fakeFileName =
          'call_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      String filePath;

      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fakeFileName';
      } else {
        filePath = fakeFileName;
      }

      _recordingPath = filePath;

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      debugPrint("녹음 시작됨: $filePath");
    } catch (e) {
      debugPrint("녹음 오류: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final isRec = await _audioRecorder.isRecording();
      if (isRec) {
        await _audioRecorder.stop();
        debugPrint("녹음 종료됨: $_recordingPath");
      }
    } catch (e) {
      debugPrint("녹음 종료 오류: $e");
    }
  }

  // =========================
  // UI
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
                  Positioned.fill(
                    child: Image.asset(
                      _selectedBackground,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned.fill(
                    child: Transform.scale(
                      scale: 0.9,
                      child: widget.avatar,
                    ),
                  ),

                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildTimerBox(),
                  ),

                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildCameraPreview(),
                  ),

                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: _buildControlButtons(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox(
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
                      colors: [Color(0xFFFFCA28), Color(0xFFFF7043)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        color: Colors.white70,
                        size: 40,
                      ),
                      const SizedBox(height: 8),

                      // 🔥 에러 메시지 표시 또는 "카메라 켜기"
                      Text(
                        _cameraErrorMessage ?? '카메라 켜기',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(Icons.chat_bubble_outline, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('채팅 기능은 준비 중입니다.')),
          );
        }),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () {
            _stopRecording();
            widget.onEndCall();
          },
          child: Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.call_end, color: Colors.white, size: 40),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _circleButton(
          _isCameraOn ? Icons.videocam_off : Icons.videocam,
          _toggleCamera,
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
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
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
