import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http_parser/http_parser.dart';

/// 본 프로그램은 브라우저의 미디어 장치(카메라)를 제어하고, 
/// 런타임 프레임을 바이너리 데이터로 변환하여 텍스트와 함께 서버로 패키징 전송하는 기술을 포함함.

const String baseUrl = 'http://localhost:8000'; // 웹이면 localhost OK

class WebAnalyzeWidget extends StatefulWidget {
  final int userId;
  const WebAnalyzeWidget({super.key, required this.userId});

  @override
  State<WebAnalyzeWidget> createState() => _WebAnalyzeWidgetState();
}

class _WebAnalyzeWidgetState extends State<WebAnalyzeWidget> {
  // 웹 하드웨어 인터페이스 추상화 레이어
  html.VideoElement? _video;
  html.CanvasElement? _canvas;
  bool _cameraReady = false;

  final _textCtrl = TextEditingController();
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebCamera();
    }
  }

  /// 독창적 기능: 저수준 웹 미디어 파이프라인 구축
  /// HTML5 Video/Canvas API를 Flutter 위젯 트리와 브릿지(Bridge)하여 실시간 제어 환경 구축
  Future<void> _initWebCamera() async {
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '320px'
      ..style.height = '240px';

    _canvas = html.CanvasElement(width: 320, height: 240);

    // 카메라 연결
    final stream = await html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true, 'audio': false});

    if (stream == null) return;

    _video!.srcObject = stream;

    // Flutter와 원시 HTML 요소 간의 ViewFactory 등록 및 렌더링 매핑
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'webcam-view',
      (int viewId) => _video!,
    );

    setState(() => _cameraReady = true);
  }

  /// 핵심 기술: 실시간 비디오 프레임 추출 알고리즘
  /// Video 스트림의 특정 시점을 Canvas에 동기화하여 JPEG 바이너리로 변환 및 메모리 적재
  Uint8List _captureJpegBytes() {
    final ctx = _canvas!.context2D;
    ctx.drawImageScaled(_video!, 0, 0, 320, 240);

    // 프레임 데이터를 DataURL로 변환 후 바이너리 디코딩 수행 (데이터 최적화)
    final dataUrl = _canvas!.toDataUrl('image/jpeg', 0.85);
    final base64Str = dataUrl.split(',').last;
    return base64Decode(base64Str);
  }

  /// 데이터 통신: 멀티모달 패키징 전송 로직
  /// 이미지(Binary)와 텍스트(String) 데이터를 Multipart 규격으로 통합하여 API 엔드포인트 전송
  Future<void> _sendAnalyze() async {
    if (!kIsWeb) return;
    if (!_cameraReady || _video == null || _canvas == null) return;

    final jpegBytes = _captureJpegBytes(); // 1장만 먼저
    final uri = Uri.parse('$baseUrl/api/v1/web/analyze');

    // HTTP Multipart 프로토콜을 이용한 복합 데이터 구조 생성
    final req = http.MultipartRequest('POST', uri);
    req.fields['user_id'] = widget.userId.toString();
    req.fields['text'] = _textCtrl.text;

    req.files.add(
      http.MultipartFile.fromBytes(
        'frames',
        jpegBytes,
        filename: 'frame.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('서버 오류 ${res.statusCode}: ${utf8.decode(res.bodyBytes)}');
    }

    setState(() {
      _result = jsonDecode(utf8.decode(res.bodyBytes));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(child: Text('이 위젯은 Web 전용입니다.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('웹 감정분석(이미지+텍스트)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_cameraReady)
              const SizedBox(
                width: 320,
                height: 240,
                child: HtmlElementView(viewType: 'webcam-view'),
              )
            else
              const SizedBox(
                width: 320,
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(
                labelText: '텍스트(대화 내용)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _sendAnalyze();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('실패: $e')),
                  );
                }
              },
              child: const Text('프레임+텍스트 분석 보내기'),
            ),
            const SizedBox(height: 12),
            if (_result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(const JsonEncoder.withIndent('  ').convert(_result)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
