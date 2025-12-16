import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http_parser/http_parser.dart';


const String baseUrl = 'http://localhost:8000'; // 웹이면 localhost OK

class WebAnalyzeWidget extends StatefulWidget {
  final int userId;
  const WebAnalyzeWidget({super.key, required this.userId});

  @override
  State<WebAnalyzeWidget> createState() => _WebAnalyzeWidgetState();
}

class _WebAnalyzeWidgetState extends State<WebAnalyzeWidget> {
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

    // Flutter에 VideoElementView로 올리기
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'webcam-view',
      (int viewId) => _video!,
    );

    setState(() => _cameraReady = true);
  }

  Uint8List _captureJpegBytes() {
    final ctx = _canvas!.context2D;
    ctx.drawImageScaled(_video!, 0, 0, 320, 240);

    final dataUrl = _canvas!.toDataUrl('image/jpeg', 0.85);
    final base64Str = dataUrl.split(',').last;
    return base64Decode(base64Str);
  }

  Future<void> _sendAnalyze() async {
    if (!kIsWeb) return;
    if (!_cameraReady || _video == null || _canvas == null) return;

    final jpegBytes = _captureJpegBytes(); // 1장만 먼저
    final uri = Uri.parse('$baseUrl/api/v1/web/analyze');

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
