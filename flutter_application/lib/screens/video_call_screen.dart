// lib/screens/video_call_screen.dart
// ignore_for_file: avoid_web_libraries_in_flutter, undefined_prefixed_name

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

import 'chat_screen.dart';
import '../services/dialogue_service.dart';

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

class _VideoCallScreenState extends State<VideoCallScreen> {
  int _seconds = 0;
  Timer? _timer;

  bool _isSending = false;
  String _lastSentText = "";

  final List<String> _backgrounds = [
    'assets/background/cafe.png',
    'assets/background/office.png',
    'assets/background/bed.png',
    'assets/background/home.png',
    'assets/background/beach.png',
    'assets/background/park.png',
  ];
  late String _selectedBackground;

  html.VideoElement? _video;
  html.MediaStream? _stream;
  bool _isCameraOn = false;
  String? _cameraErrorMessage;

  late final String _viewType;

  // ✅ 채팅 컨트롤러
  final MaldongChatController _chatController = MaldongChatController();

  // ✅ 세션 상태
  int? _sessionId;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();

    _selectedBackground = _backgrounds[Random().nextInt(_backgrounds.length)];
    _startTimer();

    if (!kIsWeb) {
      _cameraErrorMessage = "이 화면은 웹(Flutter Web) 전용입니다.";
      return;
    }

    _viewType = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';
    _initWebCamera();

    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final sid = await startCallSession(userId: widget.userId);
      if (!mounted) return;
      setState(() => _sessionId = sid);
      // ignore: avoid_print
      print("✅ session/start 성공: session_id=$_sessionId");
    } catch (e) {
      // ignore: avoid_print
      print("❌ session/start 실패: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopWebCamera();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _initWebCamera() async {
    try {
      _stopWebCamera();

      final v = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.objectFit = 'cover'
        ..style.width = '100%'
        ..style.height = '100%';

      v.setAttribute('playsinline', 'true');
      v.setAttribute('webkit-playsinline', 'true');

      final s = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': {'ideal': 'user'},
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
        'audio': false,
      });

      v.srcObject = s;

      await v.onLoadedMetadata.first;
      await v.play();

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => v,
      );

      if (!mounted) return;
      setState(() {
        _video = v;
        _stream = s;
        _isCameraOn = true;
        _cameraErrorMessage = null;
      });
    } catch (e) {
      final msg = (e is html.DomException) ? "${e.name}: ${e.message}" : e.toString();

      if (!mounted) return;
      setState(() {
        _cameraErrorMessage = "웹캠 실패: $msg";
        _isCameraOn = false;
      });

      // ignore: avoid_print
      print("웹캠 실패 상세: $msg");
    }
  }

  void _stopWebCamera() {
    try {
      _stream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    _stream = null;
    _video = null;
    _isCameraOn = false;
  }

  void _toggleCamera() {
    if (!kIsWeb) return;
    if (_isEnding) return;

    if (_isCameraOn) {
      _stopWebCamera();
      setState(() {});
    } else {
      _initWebCamera();
    }
  }

  Uint8List? _captureOneFrameJpegSync() {
    final v = _video;
    if (v == null) return null;
    if (v.videoWidth == 0 || v.videoHeight == 0) return null;

    final canvas = html.CanvasElement(width: v.videoWidth, height: v.videoHeight);
    final ctx = canvas.context2D;
    ctx.drawImage(v, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    final base64Str = dataUrl.split(',').last;
    return Uint8List.fromList(base64Decode(base64Str));
  }

  Future<List<Uint8List>> _captureFrames5fps() async {
    final frames = <Uint8List>[];

    for (int t = 0; t < 5; t++) {
      if (_video != null && _video!.videoWidth > 0 && _video!.videoHeight > 0) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    for (int i = 0; i < 5; i++) {
      final f = _captureOneFrameJpegSync();
      if (f != null) frames.add(f);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return frames;
  }

  /// ✅ 말끝날 때만 감정분석 요청 + 말동이 "생각중" 표시
  Future<void> _sendEmotionOnceWithText(String text) async {
    final trimmed = text.trim().isEmpty ? "..." : text.trim();

    if (!kIsWeb || !_isCameraOn) return;
    if (_isEnding) return;
    if (trimmed == _lastSentText) return;
    if (_isSending) return;

    _isSending = true;

    // ✅ “대답중” 말풍선 ON + 최소 표시시간 확보(깜빡임 방지)
    final startAt = DateTime.now();
    _chatController.setTyping(true);

    try {
      final frames = await _captureFrames5fps();
      if (frames.isEmpty) return;

      _lastSentText = trimmed;

      final data = await sendToMaldongWebAndPlayTts(
        text: trimmed,
        frames: frames,
        userId: widget.userId,
      );

      // ✅ 여기다 추가하면 됨 (data 받은 직후)
      print("🖼 p_img=${data['p_img']}");
      print("📝 p_text=${data['p_text']}");
      print("🎯 p_final=${data['p_final']}");
      print("✅ final_emotion=${data['final_emotion']}, conf=${data['confidence']}, risk=${data['risk_score']}");

      final reply = (data["llm_reply"] ?? "").toString().trim();
      if (reply.isNotEmpty) {
        _chatController.addBotMessage(reply);
      } else {
        // ignore: avoid_print
        print("⚠️ llm_reply 비어있음. keys=${data.keys.toList()}");
        _chatController.addBotMessage("음… 다시 한번 말씀해 주실래요?");
      }

      // ignore: avoid_print
      print("📌 응답키들: ${data.keys.toList()}");
    } catch (e) {
      // ignore: avoid_print
      print("웹 감정분석 전송 오류: $e");
      _chatController.addBotMessage("죄송해요, 지금은 연결이 불안정해요. 다시 한번 말해주실래요?");
    } finally {
      // ✅ 최소 400ms는 “생각중” 보이게
      final elapsed = DateTime.now().difference(startAt);
      final remain = 400 - elapsed.inMilliseconds;
      if (remain > 0) await Future.delayed(Duration(milliseconds: remain));

      _chatController.setTyping(false);
      _isSending = false;
    }
  }

  Future<void> _endSessionAndExit() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);

    try {
      final sid = _sessionId;
      if (sid == null) {
        // ignore: avoid_print
        print("❌ session_id가 null이라 저장 불가. session/start 확인 필요");
      } else {
        await endCallSession(sessionId: sid, userId: widget.userId);
        // ignore: avoid_print
        print("✅ session/end 저장 성공 (통화 1번 = 감정 1개)");
      }
    } catch (e) {
      // ignore: avoid_print
      print("❌ session/end 실패: $e");
    } finally {
      _timer?.cancel();
      _stopWebCamera();

      if (!mounted) return;

      widget.onEndCall();

      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        nav.maybePop();
      }

      if (mounted) setState(() => _isEnding = false);
    }
  }

  Widget _buildTimerBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatTime(_seconds),
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraErrorMessage != null) {
      return Container(
        width: 120,
        height: 160,
        color: Colors.grey[800],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_cameraErrorMessage!, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      );
    }

    if (!_isCameraOn) {
      return Container(
        width: 120,
        height: 160,
        color: Colors.black87,
        child: const Center(child: Icon(Icons.videocam_off, color: Colors.white, size: 40)),
      );
    }

    return Container(
      width: 120,
      height: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: HtmlElementView(viewType: _viewType),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 32)),
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
          behavior: HitTestBehavior.opaque,
          onTap: _isEnding ? null : _endSessionAndExit,
          child: AbsorbPointer(
            absorbing: _isEnding,
            child: Opacity(
              opacity: _isEnding ? 0.6 : 1.0,
              child: Container(
                width: 85,
                height: 85,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Center(
                  child: _isEnding
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : const Icon(Icons.call_end, color: Colors.white, size: 38),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

        _circleButton(Icons.cameraswitch, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("웹 카메라 전환은 다음 단계에서 추가할게요.")),
          );
        }),
      ],
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
                  Positioned.fill(child: Image.asset(_selectedBackground, fit: BoxFit.cover)),

                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Transform.scale(scale: 0.9, child: widget.avatar),
                    ),
                  ),

                  MaldongChatOverlay(
                    controller: _chatController,
                    onFinalText: (txt) {
                      final t = txt.trim().isEmpty ? "..." : txt.trim();
                      _sendEmotionOnceWithText(t);
                    },
                  ),

                  Positioned(top: 16, left: 16, child: _buildTimerBox()),
                  Positioned(top: 16, right: 16, child: _buildCameraPreview()),
                  Positioned(bottom: 32, left: 0, right: 0, child: _buildControlButtons()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
