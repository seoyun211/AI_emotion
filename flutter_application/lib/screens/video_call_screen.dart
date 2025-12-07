import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http; // ★ HTTP 요청
import 'chat_screen.dart';

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
  // 카메라
  // =========================

  Future<void> _initCamera() async {
    try {
      if (kIsWeb) {
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
        });
        return;
      }

      if (cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용 가능한 카메라가 없습니다.')),
        );
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
      });
    } catch (e) {
      debugPrint("카메라 초기화 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 사용 불가: $e')),
        );
      }
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

      // record 패키지에서 path가 required String 이라서
      // 무조건 non-null 문자열을 만들어서 넘긴다.
      final fakeFileName =
          'call_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      String filePath;

      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fakeFileName';
      } else {
        // 웹에서는 파일 시스템 경로 개념이 없으니 이름만 넘겨도 됨
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
        debugPrint("녹음 종료됨, path: $_recordingPath");
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
                  // 1. 배경 이미지
                  Positioned.fill(
                    child: Image.asset(_selectedBackground, fit: BoxFit.cover),
                  ),
                  
                  // 2. 말동이 아바타
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 0.9,
                      child: widget.avatar,
                    ),
                  ),

                  // 🔥 3. 새로 만든 채팅창 레이어 추가 (말동이 위에 쌓임)
                  // 말동이 좌측 공간에 위치하도록 설정되어 있음
                  const MaldongChatOverlay(), 

                  // 4. 통화 타이머
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildTimerBox(),
                  ),

                  // 5. 내 카메라 미리보기
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildCameraPreview(),
                  ),

                  // 6. 하단 컨트롤 버튼
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
                    children: const [
                      Icon(Icons.camera_alt, color: Colors.white70, size: 40),
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
    );
  }

  Widget _buildControlButtons() {
    return Row(
    mainAxisAlignment: MainAxisAlignment.center, // 👈 가로 정중앙 정렬
    children: [
      // 📹 카메라 토글 버튼 (왼쪽)
      _circleButton(
        _isCameraOn ? Icons.videocam_off : Icons.videocam,
        _toggleCamera,
      ),
      const SizedBox(width: 20),

      // 📞 종료 버튼 (정중앙)
      GestureDetector(
        onTap: () async {
          _stopRecording();
          _stopEmotionLoop();
          await _endCallOnServer();
          widget.onEndCall();
        },
        child: Container(
          width: 85,
          height: 85,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.call_end, color: Colors.white, size: 38),
          ),
        ),
      ),
      const SizedBox(width: 20),

      // 🔄 카메라 전환 버튼 (오른쪽)
      _circleButton(
        Icons.cameraswitch,
        _switchCamera,
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
