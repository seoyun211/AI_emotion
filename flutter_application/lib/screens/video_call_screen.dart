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
import 'package:audioplayers/audioplayers.dart'; 

import '../main.dart';
import '../maldong_avatar.dart';
import '../services/dialogue_service.dart';

// 본인 환경에 맞게 수정 (예: http://10.0.2.2:8000)
const String baseUrl = 'http://localhost:8000';

// ★ 대화 상태 정의 (VAD 기반 루프)
enum ConversationState {
  idle,
  listening,
  processing,
  speaking,
}

// ★ 대화 메시지 모델 (UI 채팅 목록용)
enum MessageSender { user, maldong }

class DialogueMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  DialogueMessage({required this.text, required this.sender, required this.timestamp});
}


class VideoCallScreen extends StatefulWidget {
  final VoidCallback onEndCall;
  final Widget avatar;
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

class _VideoCallScreenState extends State<VideoCallScreen> { // <-- 클래스 시작
  // -------------------------
  // 타이머 & 카메라 & 기본 설정
  // -------------------------
  int _seconds = 0;
  Timer? _timer;
  CameraController? _cameraController;
  bool _isCameraOn = false;
  String? _cameraErrorMessage;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  int _currentCameraIndex = 0;
  Timer? _emotionTimer;
  bool _isAnalyzing = false;
  final AudioPlayer maldongTtsPlayer = AudioPlayer(); 
  int? _sessionId;

  // -------------------------
  // 🔥 자동 대화 상태 & 데이터
  // -------------------------
  ConversationState _state = ConversationState.idle;
  List<DialogueMessage> _messages = [];
  String _currentStatusMessage = "통화 시작 중...";
  bool _isMicMonitoringActive = false; 

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

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initCamera();
      });
    }

    _setupAudioPlayerListener();
    _startEmotionLoop();
    _startCallOnServer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emotionTimer?.cancel();
    _cameraController?.dispose();
    _stopRecording();
    maldongTtsPlayer.dispose(); 
    
    if (_sessionId != null) {
      _endCallOnServer();
    }
    super.dispose();
  }

  // -------------------------
  // 상태 관리 & 유틸리티
  // -------------------------
  void _setState(ConversationState newState) {
    if (!mounted) return;
    debugPrint('🔄 상태 변경: ${_state.name} -> ${newState.name}');
    setState(() {
      _state = newState;
      _currentStatusMessage = _getStatusText(newState);
    });

    if (newState == ConversationState.listening) {
      _startUserTurn();
    }
  }
  
  void _addMessage(DialogueMessage message) {
    setState(() {
      _messages.add(message);
    });
    // TODO: 메시지 추가 후 ListView를 최하단으로 스크롤하는 로직 추가 필요
  }

  String _getStatusText(ConversationState state) {
    switch (state) {
      case ConversationState.idle: return "통화 종료";
      case ConversationState.listening: return "말씀해주세요...";
      case ConversationState.processing: return "서버 처리 중...";
      case ConversationState.speaking: return "말동이 응답 중...";
    }
  }

  void _setupAudioPlayerListener() {
    maldongTtsPlayer.onPlayerComplete.listen((event) {
      if (_state == ConversationState.speaking) {
        _setState(ConversationState.listening);
      }
    });
  }

  // =========================
  // 🗣️ 자동 대화 로직 (VAD 기반)
  // =========================

  Future<void> _runConversationLoop() async {
    _addMessage(DialogueMessage(
      text: '말동이가 연결되었습니다. 먼저 말씀해주세요.',
      sender: MessageSender.maldong,
      timestamp: DateTime.now(),
    ));
    _setState(ConversationState.listening);
  }

  Future<void> _startUserTurn() async {
    if (_state != ConversationState.listening || _sessionId == null) return;
    if (_isMicMonitoringActive) return;

    try {
      // 1. 녹음 시작 (웹/모바일 분기 처리)
      String? filePath;
      
      if (!kIsWeb) { // 모바일/데스크톱
        final dir = await getTemporaryDirectory();
        filePath = '${dir.path}/auto_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingPath = filePath;
      } 
      
      final recordConfig = const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000);

      // 🔥 [수정] path가 null일 때 빈 문자열 '' 전달 (Required Parameter 에러 해결)
      await _audioRecorder.start(
        recordConfig, 
        path: filePath ?? '',
      );
      
      if (!mounted) return;
      _isMicMonitoringActive = true;

      // 2. VAD: 3초 무음 감지 대기 (임시 구현)
      final isSilence = await _waitForSilence(duration: const Duration(seconds: 3));

      // 3. 무음 감지 시 녹음 종료 및 API 전송
      if (isSilence) {
        dynamic recordedData = await _audioRecorder.stop();
        _isMicMonitoringActive = false;

        Uint8List? audioBytes;
        
        if (recordedData is String) { // 모바일/데스크톱: 경로를 바이트로 변환
            audioBytes = await File(recordedData).readAsBytes();
        } else if (recordedData is Uint8List) { // 웹: 바이트 배열 그대로 사용
            audioBytes = recordedData;
        }

        if (audioBytes != null) {
            _setState(ConversationState.processing);
            await _processTurnWithBytes(audioBytes);
        } else {
            debugPrint("녹음 데이터 획득 실패.");
            _setState(ConversationState.listening);
        }
      } else {
          _isMicMonitoringActive = false; 
          _setState(ConversationState.listening);
      }

    } catch (e) {
      _isMicMonitoringActive = false;
      debugPrint("자동 대화 턴 시작 오류: $e");
      _setState(ConversationState.listening); 
    }
  }

  Future<void> _processTurnWithBytes(Uint8List audioBytes) async {
    if (_sessionId == null) return;
    
    try {
        final result = await sendAudioForDialogue(
            audioBytes: audioBytes,
            sessionId: _sessionId!,
        );

        if (result != null) {
            _addMessage(DialogueMessage(
                text: result.userSttText, sender: MessageSender.user, timestamp: DateTime.now(),
            ));
            
            _addMessage(DialogueMessage(
                text: result.maldongResponseText, sender: MessageSender.maldong, timestamp: DateTime.now(),
            ));
            
            _setState(ConversationState.speaking);
        } else {
            _addMessage(DialogueMessage(
                text: '서버 응답이 없습니다. 다시 말씀해주세요.', sender: MessageSender.maldong, timestamp: DateTime.now(),
            ));
            _setState(ConversationState.listening); 
        }

    } catch (e) {
        debugPrint("대화 처리 오류: $e");
        _addMessage(DialogueMessage(
            text: '통신 오류 발생: $e', sender: MessageSender.maldong, timestamp: DateTime.now(),
        ));
        _setState(ConversationState.listening);
    }
  }
  
  Future<bool> _waitForSilence({required Duration duration}) async {
      await Future.delayed(const Duration(seconds: 5)); 
      if (!mounted) return false;
      final isRecording = await _audioRecorder.isRecording();
      return isRecording;
  }

  // =========================
  // 🔗 통화 기록 API 연동
  // =========================

  Future<void> _startCallOnServer() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/calls/start');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _sessionId = data['session_id'] as int;
        });
        debugPrint('통화 시작 기록 성공: session_id = $_sessionId');
        _runConversationLoop();
      } else {
        debugPrint(
            '통화 시작 기록 실패: ${response.statusCode} ${response.body}');
        setState(() { _currentStatusMessage = "통화 시작 실패 (서버)"; });
      }
    } catch (e) {
      debugPrint('통화 시작 네트워크 오류: $e');
      setState(() { _currentStatusMessage = "통화 시작 실패 (네트워크)"; });
    }
  }

  Future<void> _endCallOnServer() async {
    if (_sessionId == null) return;

    try {
      final url = Uri.parse('$baseUrl/api/v1/calls/$_sessionId/end');
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('통화 종료 기록 성공: session_id = $_sessionId');
    } catch (e) {
      debugPrint('통화 종료 네트워크 오류: $e');
    }
  }
  
  // =========================
  // 🔥 복원된 함수들 및 카메라 (웹 우회 로직 반영)
  // =========================
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds++;
      });
    });
  }

  void _startEmotionLoop() {
    _emotionTimer?.cancel();
    _emotionTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_state != ConversationState.listening && _state != ConversationState.speaking) return;
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
      final audioBytes = await _recordShortAudio();
      final frameBytesList = await _captureFrames(count: 3);

      await sendToMaldongAndPlayTts(
        audioBytes: audioBytes,
        frameBytesList: frameBytesList,
        userId: widget.userId,
        sessionId: _sessionId,
      );
    } catch (e) {
      debugPrint("감정분석 사이클 오류: $e");
    } finally {
      _isAnalyzing = false;
    }
  }

  // 🔥 _recordShortAudio 함수 (웹 우회 로직 반영)
  Future<Uint8List> _recordShortAudio() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("마이크 권한이 없습니다.");
    }

    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) throw Exception("녹음 권한 없음");
    
    String? filePath;
    
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      filePath = '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    
    final recordConfig = const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
    );

    // 🔥 [수정] path가 null일 때 빈 문자열 '' 전달
    await _audioRecorder.start(
      recordConfig, 
      path: filePath ?? '',
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    // 웹: stop()은 Uint8List를 반환, 모바일: String 경로를 반환
    dynamic recordedData = await _audioRecorder.stop();
    
    if (recordedData is String) {
        final file = File(recordedData);
        return await file.readAsBytes();
    } else if (recordedData is Uint8List) {
        return recordedData;
    } else {
        throw Exception("녹음 실패: 데이터 획득 불가");
    }
  }
  
  // =========================
  // 기타 헬퍼 및 UI 함수 (클래스 내부에 복원)
  // =========================
  
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

  Future<List<Uint8List>> _captureFrames({int count = 1}) async {
    final List<Uint8List> frames = [];

    if (!_isCameraOn || _cameraController == null || !_cameraController!.value.isInitialized) {
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
  
  Future<void> _initCamera() async {
    // ... (카메라 초기화 로직)
  }
  Future<void> _toggleCamera() async {
    // ... (카메라 토글 로직)
  }
  Future<void> _switchCamera() async {
    // ... (카메라 전환 로직)
  }

  // =========================
  // UI 빌드 (클래스 필수 멤버 복원)
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 배경
            Positioned.fill(
              child: Image.asset(_selectedBackground, fit: BoxFit.cover),
            ),
            // 2. 말동이 아바타
            Positioned.fill(
              child: Transform.scale(scale: 0.9, child: widget.avatar),
            ),
            
            // 3. 타이머 박스 및 상태 (좌상단)
            Positioned(top: 16, left: 16, child: _buildTimerBox()),
            
            // 4. 채팅 목록 (스크롤 가능)
            Positioned(
              bottom: 120, 
              left: 0,
              right: 0,
              height: 350,
              child: _buildChatList(), 
            ),
            
            // 5. 통화 제어 버튼 (하단)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: _buildMinimalControls(),
            ),
            
            // 6. 현재 상태 오버레이 (말씀해주세요/처리 중)
            if (_state != ConversationState.idle && _state != ConversationState.speaking)
              Positioned(
                bottom: 230,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _currentStatusMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            
            // 7. 카메라 미리보기
            Positioned(top: 16, right: 16, child: _buildCameraPreview()),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        final isUser = message.sender == MessageSender.user;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue.withOpacity(0.8) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
            ),
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              isUser ? '나: ${message.text}' : message.text, 
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            _stopRecording();
            _stopEmotionLoop();
            await _endCallOnServer();
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
      ],
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
                '대화통화중',
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
} // <-- 클래스 끝