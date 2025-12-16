// lib/services/web_camera_capture_stub.dart
import 'dart:typed_data';

class WebCameraCapture {
  Future<void> init() async {
    throw UnsupportedError('WebCameraCapture는 Web에서만 지원됩니다.');
  }

  dynamic get videoElement =>
      throw UnsupportedError('Web에서만 videoElement를 사용할 수 있습니다.');

  Future<List<Uint8List>> captureFrames({int count = 5}) async {
    throw UnsupportedError('Web에서만 프레임 캡처가 가능합니다.');
  }

  void dispose() {}
}
