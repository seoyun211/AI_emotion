// lib/services/web_speech_stt_web.dart
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'dart:html' as html;
import 'dart:js' as js;              // ✅ allowInterop는 여기!
import 'dart:js_util' as jsu;        // ✅ 웹에서만 존재
typedef OnText = void Function(String text, bool isFinal);

class WebSpeechStt {
  bool _isAvailable = true;
  bool _isListening = false;
  dynamic _rec;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  VoidCallback? onStart;
  VoidCallback? onEnd;
  void Function(String error)? onError;
  OnText? onText;

  Future<void> init({String lang = "ko-KR"}) async {
    if (!kIsWeb) {
      _isAvailable = false;
      return;
    }

    final win = jsu.getProperty(html.window, 'window');

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

    jsu.setProperty(_rec, 'onstart', js.allowInterop((_) {
      _isListening = true;
      onStart?.call();
    }));

    jsu.setProperty(_rec, 'onend', js.allowInterop((_) {
      _isListening = false;
      onEnd?.call();
    }));

    jsu.setProperty(_rec, 'onerror', js.allowInterop((e) {
      final msg = (jsu.getProperty(e, 'error')?.toString() ?? 'unknown');
      _isListening = false;
      onError?.call(msg);
    }));

    jsu.setProperty(_rec, 'onresult', js.allowInterop((dynamic e) {
      try {
        final results = jsu.getProperty(e, 'results');
        final len = jsu.getProperty(results, 'length') as int;
        if (len <= 0) return;

        final last = jsu.getProperty(results, len - 1);
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
    if (!_isAvailable || _rec == null || _isListening) return;
    try {
      jsu.callMethod(_rec, 'start', []);
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  void stop() {
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
