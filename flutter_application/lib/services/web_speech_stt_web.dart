// lib/services/web_speech_stt_web.dart
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'dart:html' as html;
import 'dart:js_util' as jsu;
import 'package:js/js.dart' show allowInterop;

typedef OnText = void Function(String text, bool isFinal);

class WebSpeechSttWeb {
  bool _isAvailable = true;
  bool _isListening = false;
  dynamic _rec;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  VoidCallback? onStart;
  VoidCallback? onEnd;
  void Function(String error)? onError;

  /// 매 결과마다 호출됨
  /// - isFinal==false: 중간(interim)
  /// - isFinal==true : 확정(final)
  OnText? onText;

  Future<void> init({String lang = "ko-KR"}) async {
    if (!kIsWeb) {
      _isAvailable = false;
      return;
    }

    // window 객체
    final win = jsu.getProperty(html.window, 'window');

    // Chrome/Edge: SpeechRecognition, Safari: webkitSpeechRecognition
    dynamic ctor;
    if (jsu.hasProperty(win, 'SpeechRecognition')) {
      ctor = jsu.getProperty(win, 'SpeechRecognition');
    } else if (jsu.hasProperty(win, 'webkitSpeechRecognition')) {
      ctor = jsu.getProperty(win, 'webkitSpeechRecognition');
    } else {
      _isAvailable = false;
      return;
    }

    _rec = jsu.callConstructor(ctor, []);

    jsu.setProperty(_rec, 'lang', lang);
    jsu.setProperty(_rec, 'continuous', true);
    jsu.setProperty(_rec, 'interimResults', true);

    jsu.setProperty(_rec, 'onstart', allowInterop((_) {
      _isListening = true;
      onStart?.call();
    }));

    jsu.setProperty(_rec, 'onend', allowInterop((_) {
      _isListening = false;
      onEnd?.call();
    }));

    jsu.setProperty(_rec, 'onerror', allowInterop((e) {
      final msg = (jsu.getProperty(e, 'error')?.toString() ?? 'unknown');
      _isListening = false;
      onError?.call(msg);
    }));

    // ✅ 타입은 dynamic으로 받기
    jsu.setProperty(_rec, 'onresult', allowInterop((dynamic e) {
      try {
        final results = jsu.getProperty(e, 'results');
        final len = jsu.getProperty(results, 'length') as int;
        if (len <= 0) return;

        final lastIndex = len - 1;
        final last = jsu.getProperty(results, lastIndex);

        final isFinal = (jsu.getProperty(last, 'isFinal') as bool?) ?? false;

        final alt0 = jsu.getProperty(last, 0);
        final transcript =
            (jsu.getProperty(alt0, 'transcript')?.toString() ?? '').trim();

        if (transcript.isEmpty) return;
        onText?.call(transcript, isFinal);
      } catch (err) {
        onError?.call(err.toString());
      }
    }));
  }

  void start() {
    if (!kIsWeb) return;
    if (!_isAvailable || _rec == null) return;
    if (_isListening) return;

    try {
      jsu.callMethod(_rec, 'start', []);
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  void stop() {
    if (!kIsWeb) return;
    if (_rec == null) return;

    try {
      jsu.callMethod(_rec, 'stop', []);
    } catch (_) {}
  }

  void dispose() {
    stop();
    _rec = null;
    _isListening = false;
  }
}
