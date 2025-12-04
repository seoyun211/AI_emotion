import 'dart:async';
import 'dart:math';
import 'dart:io';              // ★ 음성 파일 읽기용 (모바일/데스크톱용)
import 'dart:typed_data';      // ★ 바이트 배열(Uint8List) 사용

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import '../maldong_avatar.dart';
import '../services/dialogue_service.dart'; // ★ /dialogue/speak + TTS 재생 함수

class VideoCallScreen extends StatefulWidget {
  final VoidCallback onEndCall;
  final Widget avatar;

  // ★ (선택) 나중에 진짜 userId 쓰고 싶으면 여기에 userId 추가해도 됨
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

  // 🔥 카메라 에러 메시지 저장용
  String? _cameraErrorMessage;

  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

  // ★ 현재 사용 중인 카메라 인덱스 (0: 기본, 1: 다른 카메라)
  int _currentCameraIndex = 0;

  // ★ 감정분석 주기적 수행용 타이머
  Timer? _emotionTimer;
  bool _isAnalyzing = false; // 동시에 두 번 안 돌게 막기

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

    // 🔥 통화 시작 == 이 화면에 들어오자마자 라고 가정
    //    1) 카메라 준비
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initCamera();
      });
    }
    // 모바일에서는 사용자가 우측 상단 "카메라 켜기"를 눌러도 되고,
    // 자동으로 켜고 싶다면 여기서 _initCamera()를 호출해도 됨.
    // 예: if (!kIsWeb) _initCamera();

    // 2) 감정분석(음성+프레임+LLM+TTS) 주기적 시작
    _startEmotionLoop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _stopRecording();
    _stopEmotionLoop(); // ★ 감정분석 타이머도 정리
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
  // (NEW) 감정 분석 루프
  // =========================

  // ★ 5초마다 한 번씩: 음성 1~2초 녹음 + 프레임 캡처 + /dialogue/speak 호출
  void _startEmotionLoop() {
    _emotionTimer?.cancel();
    _emotionTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _runEmotionCycle();
    });
  }

  void _stopEmotionLoop() {
    _emotionTimer?.cancel();
    _emotionTimer = null;
  }

  Future<void> _runEmotionCycle() async {
    // 웹에서는 record/dart:io 지원이 안 되므로, 감정분석 루프는 모바일/데스크톱에서만 돌도록
    if (kIsWeb) return;

    if (_isAnalyzing) return;
    _isAnalyzing = true;

    try {
      // 1) 음성 1~2초 녹음
      final audioBytes = await _recordShortAudio();

      // 2) 카메라 프레임 2~3장 캡처 (카메라 꺼져 있으면 빈 리스트)
      final frameBytesList = await _captureFrames(count: 3);

      // 3) 백엔드 /dialogue/speak 호출 + 말동이 TTS 재생
      await sendToMaldongAndPlayTts(
        audioBytes: audioBytes,
        frameBytesList: frameBytesList,
        userId: 1, // ★ TODO: 로그인 연결 후 실제 userId로 교체
      );
    } catch (e) {
      debugPrint("감정분석 사이클 오류: $e");
    } finally {
      _isAnalyzing = false;
    }
  }

  // 🔊 1~2초 짧게 녹음해서 Uint8List 반환
  Future<Uint8List> _recordShortAudio() async {
    // 마이크 권한
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("마이크 권한이 없습니다.");
    }

    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) throw Exception("녹음 권한 없음");

    // 임시 파일 경로
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.m4a';

    _recordingPath = filePath;

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
      ),
      path: filePath,
    );

    // 🔹 1.5초 정도 녹음
    await Future.delayed(const Duration(milliseconds: 1500));

    final path = await _audioRecorder.stop();
    if (path == null) {
      throw Exception("녹음 실패 (path == null)");
    }

    final file = File(path);
    return await file.readAsBytes();
  }

  // 📸 카메라로 프레임 여러 장 캡처해서 List<Uint8List>로 반환
  Future<List<Uint8List>> _captureFrames({int count = 1}) async {
    final List<Uint8List> frames = [];

    if (!_isCameraOn ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      // 카메라 꺼져 있으면 프레임 없이도 감정분석은 돌아감 (텍스트/음성 기반)
      return frames;
    }

    try {
      for (int i = 0; i < count; i++) {
        final XFile xfile = await _cameraController!.takePicture();
        final bytes = await xfile.readAsBytes();
        frames.add(bytes);
      }
    } catch (e) {
      debugPrint("프레임 캡처 실패: $e");
    }

    return frames;
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

        final camera = cameras[_currentCameraIndex % cameras.length];
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

      final camera = cameras[_currentCameraIndex % cameras.length];
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

  // ★ 전면/후면 카메라 전환
  Future<void> _switchCamera() async {
    if (cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("다른 카메라가 없습니다.")),
      );
      return;
    }

    _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;

    await _cameraController?.dispose();
    await _initCamera();
  }

  // =========================
  // (기존) 전체 통화 녹음 종료용 (지금은 감정분석용 짧은 녹음만 사용)
  // =========================

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

                      // 에러 메시지 표시 또는 "카메라 켜기"
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
            _stopEmotionLoop(); // ★ 통화 종료 시 감정분석도 정지
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
        const SizedBox(width: 16),
        // ★ 전면/후면 전환 버튼
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