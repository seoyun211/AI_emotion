// lib/services/web_camera_capture_web.dart
import 'dart:async';
import 'dart:convert'; // ✅ base64Decode
import 'dart:typed_data';
import 'dart:html' as html;

class WebCameraCapture {
  html.VideoElement? _video;
  html.MediaStream? _stream;

  Future<void> init() async {
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true;

    // ✅ playsInline 은 attribute로
    _video!.setAttribute('playsinline', 'true');
    _video!.setAttribute('webkit-playsinline', 'true');

    // ✅ 권한 요청 (오디오 필요없으면 video만)
    _stream = await html.window.navigator.mediaDevices!.getUserMedia({
      'video': {
        'facingMode': 'user', // 전면 카메라 우선
      },
      'audio': false,
    });

    _video!.srcObject = _stream;

    // ✅ Safari 계열 안전하게
    await _video!.play();
  }

  html.VideoElement get videoElement => _video!;

  /// ✅ 5fps로 count장 캡처해서 JPEG bytes(Uint8List)로 반환
  /// - toBlob/FileReader 대신 toDataUrl 사용 (타입오류/빨간줄 방지)
  Future<List<Uint8List>> captureFrames({int count = 5}) async {
    if (_video == null) return [];

    // 메타데이터 준비될 때까지 대기
    if (_video!.videoWidth == 0 || _video!.videoHeight == 0) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final frames = <Uint8List>[];

    final canvas = html.CanvasElement(
      width: _video!.videoWidth,
      height: _video!.videoHeight,
    );
    final ctx = canvas.context2D;

    for (int i = 0; i < count; i++) {
      ctx.drawImage(_video!, 0, 0);

      // "data:image/jpeg;base64,...."
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
      final base64Str = dataUrl.split(',').last;
      final bytes = base64Decode(base64Str);

      frames.add(Uint8List.fromList(bytes));

      await Future.delayed(const Duration(milliseconds: 200)); // ✅ 5fps
    }

    return frames;
  }

  void dispose() {
    _stream?.getTracks().forEach((t) => t.stop());
    _stream = null;
    _video = null;
  }
}
