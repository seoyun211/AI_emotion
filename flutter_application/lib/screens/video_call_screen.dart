import 'dart:async';
import 'dart:math';
import 'dart:io'; 
import 'dart:typed_data'; 
import 'dart:convert'; 

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http; 
import 'chat_screen.dart'; // MaldongChatOverlay 포함

import '../main.dart';
import '../maldong_avatar.dart';
import '../services/dialogue_service.dart'; 

// ★ 본인 환경에 맞게 수정 (이 라우터에서는 통화 시작/종료 API를 사용하지 않음)
const String baseUrl = 'http://localhost:8000';

class VideoCallScreen extends StatefulWidget {
    final VoidCallback onEndCall;
    final Widget avatar;

    // ★ 실제 유저 정보 (ChatOverlay로 전달하지 않으므로 사용처가 줄어듦)
    final int userId;
    final String accessToken;

    const VideoCallScreen({
        super.key,
        required this.onEndCall,
        required this.avatar,
        required this.userId,
        required this.accessToken,
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

    // ★ 현재 사용 중인 카메라 인덱스
    int _currentCameraIndex = 0;

    // ★ 감정분석 주기적 수행용 타이머
    Timer? _emotionTimer;
    bool _isAnalyzing = false; 

    final List<String> _backgrounds = [
        'assets/background/cafe.png',
        'assets/background/office.png',
        'assets/background/bed.png',
        'assets/background/home.png',
        'assets/background/beach.png',
        'assets/background/park.png',
    ];

    late String _selectedBackground;

    // ❌ 제거: 통화 세션 ID는 이제 ChatOverlay가 관리합니다.
    // int? _sessionId; 

    @override
    void initState() {
        super.initState();
        _selectedBackground = _backgrounds[Random().nextInt(_backgrounds.length)];
        _startTimer();

        // 🔥 카메라 초기화
        if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                _initCamera();
            });
        }

        _startEmotionLoop();
    }

    @override
    void dispose() {
        _timer?.cancel();
        _cameraController?.dispose();
        _stopRecording();
        _stopEmotionLoop();
        super.dispose();
    }

    // =========================
    // ⏱ 타이머
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
    // 📸 카메라/녹음 컨트롤
    // =========================

    // 1. 카메라 초기화 (initState에서 호출됨)
    Future<void> _initCamera() async {
        // 웹 환경에서는 권한 요청이 필요 없습니다.
        if (!kIsWeb) {
            final status = await Permission.camera.request();
            if (!status.isGranted) {
                setState(() {
                    _cameraErrorMessage = '카메라 권한이 거부되었습니다.';
                });
                return;
            }
        }

        try {
            final cameras = await availableCameras();
            if (cameras.isEmpty) {
                setState(() {
                    _cameraErrorMessage = '사용 가능한 카메라가 없습니다.';
                });
                return;
            }
            
            // 현재 인덱스에 맞는 카메라 사용
            final camera = cameras[_currentCameraIndex % cameras.length];
            _cameraController = CameraController(
                camera,
                ResolutionPreset.medium,
                enableAudio: false,
            );

            await _cameraController!.initialize();
            setState(() {
                _isCameraOn = true;
            });
        } on CameraException catch (e) {
            setState(() {
                _cameraErrorMessage = '카메라 초기화 오류: ${e.code}';
            });
        }
    }

    // 2. 카메라 켜기/끄기 토글 (UI에서 호출됨)
    void _toggleCamera() {
        if (_cameraController == null) return;

        if (_isCameraOn) {
            // 카메라 끄기
            _cameraController!.dispose();
            _cameraController = null;
            setState(() {
                _isCameraOn = false;
            });
        } else {
            // 카메라 켜기
            _initCamera();
        }
    }

    // 3. 카메라 전환 (UI에서 호출됨)
    Future<void> _switchCamera() async {
        if (_cameraController == null) return;

        final cameras = await availableCameras();
        if (cameras.length <= 1) return; // 카메라가 하나뿐이면 전환할 수 없음

        _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
        await _cameraController!.dispose();

        // 새 인덱스로 카메라 다시 초기화
        _initCamera();
    }

    // 4. 오디오 녹음 중지 (dispose 및 통화 종료 시 호출됨)
    Future<void> _stopRecording() async {
        if (await _audioRecorder.isRecording()) {
            await _audioRecorder.stop();
        }
    }

    // =========================
    // 🎙 미디어 캡처 (감정 분석용)
    // =========================

    // 1. 짧은 오디오 녹음
    Future<Uint8List> _recordShortAudio() async {
        if (kIsWeb) return Uint8List(0);
        
        // 권한 확인 및 요청
        if (!await Permission.microphone.request().isGranted) {
            debugPrint("마이크 권한 없음");
            return Uint8List(0);
        }
        
        try {
            final dir = await getTemporaryDirectory();
            final path = '${dir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp4';

            await _audioRecorder.start(
                const RecordConfig(encoder: AudioEncoder.aacLc), 
                path: path
            );
            
            // 1초 녹음 후 중지
            await Future.delayed(const Duration(seconds: 1));
            final resultPath = await _audioRecorder.stop();

            if (resultPath != null) {
                final file = File(resultPath);
                final bytes = await file.readAsBytes();
                await file.delete(); // 임시 파일 삭제
                return bytes;
            }
        } catch (e) {
            debugPrint("오디오 녹음 오류: $e");
        }
        return Uint8List(0);
    }

    // 2. 프레임 캡처
    Future<List<Uint8List>> _captureFrames({int count = 1}) async {
        if (!_isCameraOn || _cameraController == null || !_cameraController!.value.isInitialized) {
            debugPrint("카메라가 준비되지 않아 프레임 캡처를 건너뜁니다.");
            return [];
        }

        final List<Uint8List> frameBytesList = [];
        try {
            for (int i = 0; i < count; i++) {
                final XFile file = await _cameraController!.takePicture();
                final Uint8List bytes = await file.readAsBytes();
                frameBytesList.add(bytes);
                // 프레임 간격 (너무 빨리 캡처하면 오류가 날 수 있음)
                if (i < count - 1) {
                    await Future.delayed(const Duration(milliseconds: 200)); 
                }
            }
        } on CameraException catch (e) {
            debugPrint("프레임 캡처 오류: $e");
        }
        return frameBytesList;
    }


    // =========================
    // 감정 분석 루프
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
        if (kIsWeb) return;

        if (_isAnalyzing) return;
        _isAnalyzing = true;

        try {
            // 1) 음성 1~2초 녹음
            final audioBytes = await _recordShortAudio();

            // 2) 카메라 프레임 2~3장 캡처 (카메라 꺼져 있으면 빈 리스트)
            final frameBytesList = await _captureFrames(count: 3);

            // 3) 백엔드 /dialogue/speak 호출 + 말동이 TTS 재생
            final result = await sendToMaldongAndPlayTts(
                audioBytes: audioBytes,
                frameBytesList: frameBytesList,
                userId: widget.userId, 
            );
            
        } catch (e) {
            debugPrint("감정분석 사이클 오류: $e");
        } finally {
            _isAnalyzing = false;
        }
    }

    // =========================
    // 🖼 UI 빌더
    // =========================

    // 1. 타이머 UI
    Widget _buildTimerBox() {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20)
            ),
            child: Text(
                _formatTime(_seconds),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
        );
    }

    // 2. 카메라 미리보기 UI
    Widget _buildCameraPreview() {
        if (_cameraErrorMessage != null) {
            return Container(
                width: 120, height: 160,
                color: Colors.grey[800],
                child: Center(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_cameraErrorMessage!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                ),
            );
        }
        
        if (!_isCameraOn || _cameraController == null || !_cameraController!.value.isInitialized) {
            return Container(
                width: 120, height: 160,
                color: Colors.black87,
                child: const Center(
                    child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
                ),
            );
        }

        final size = MediaQuery.of(context).size;
        final scale = size.aspectRatio * _cameraController!.value.aspectRatio;

        // 카메라 피드를 화면 비율에 맞게 표시
        return Container(
            width: 120, // 작은 미리보기 크기
            height: 160,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
            ),
            child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                    width: 100 * scale, 
                    height: 100, 
                    child: CameraPreview(_cameraController!),
                ),
            ),
        );
    }

    Widget _buildControlButtons() {
        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                _circleButton(_isCameraOn ? Icons.videocam_off : Icons.videocam, _toggleCamera),
                const SizedBox(width: 20),
                GestureDetector(
                    onTap: () async {
                        // 1. 미디어/감정 분석 중지
                        _stopRecording();
                        _stopEmotionLoop();
                        
                        // 2. 이 화면을 닫습니다. (onEndCall 호출)
                        //    화면이 닫히면 -> MaldongChatOverlay의 dispose()가 자동 호출되고 -> 
                        //    dispose() 안의 _endSessionOnServer()가 실행되어 최종 녹취록이 저장됩니다.
                        widget.onEndCall(); 
                    },
                    child: Container(
                        width: 85, height: 85,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Center(child: Icon(Icons.call_end, color: Colors.white, size: 38)),
                    ),
                ),
                const SizedBox(width: 20),
                _circleButton(Icons.cameraswitch, _switchCamera),
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

                                    const MaldongChatOverlay(), // ★ ChatOverlay가 dispose될 때 세션 종료

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
}