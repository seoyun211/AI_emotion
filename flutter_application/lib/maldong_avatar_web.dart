import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MaldongAvatarWeb extends StatefulWidget {
  const MaldongAvatarWeb({super.key});

  @override
  State<MaldongAvatarWeb> createState() => _MaldongAvatarWebState();
}

class _MaldongAvatarWebState extends State<MaldongAvatarWeb> {
  late final WebViewController _controller;

  static const String _avatarHtml = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>

    <style>
      html, body {
        margin: 0;
        padding: 0;
        overflow: hidden;
        background: transparent;
      }

      model-viewer {
        width: 100vw;
        height: 100vh;
        /* ❌ 너무 과하게 확대했던 거 제거
           필요하면 나중에 scale(1.1) 정도만 살짝 줄 수 있음 */
        /* transform: scale(1.6);
        transform-origin: center bottom; */
      }
    </style>
  </head>

  <body>
    <model-viewer
      id="avatar"
      src="https://models.readyplayer.me/690d8484132e61458cf8e667.glb"

      /* 🔥 회전 끄기 */
      /* auto-rotate 지우기 */
      disable-zoom
      interaction-prompt="none"
      interaction-policy="none"
      exposure="1.0"
      shadow-intensity="1.0"
      environment-image="neutral"

      /* 🔥 카메라 위치: 살짝 멀게 + 윗부분도 보이게 */
      camera-controls="false"
      camera-orbit="0deg 70deg 1.8m"
      camera-target="0m 1.35m 0m"
      field-of-view="30deg"
    >
    </model-viewer>

    <script>
      const avatar = document.getElementById('avatar');
      avatar.addEventListener('load', () => {
        console.log('avatar loaded');
      });

      window.blinkOnce = function () {
        console.log("blinkOnce() called from Flutter");
      };

      window.smile = function () {
        console.log("smile() called from Flutter");
      };
    </script>
  </body>
</html>
''';

  @override
  void initState() {
    super.initState();

    final controller = WebViewController();

    if (!kIsWeb) {
      // 📱 안드/ios → 로컬 HTML 사용
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.loadFlutterAsset('assets/web/avatar_viewer.html');
    } else {
      // 💻 Flutter Web → 위의 _avatarHtml 사용
      final htmlWithNoCache =
          _avatarHtml + "<!-- ${DateTime.now().millisecondsSinceEpoch} -->";

      controller.loadRequest(
        Uri.dataFromString(
          htmlWithNoCache,
          mimeType: 'text/html',
          encoding: utf8,
        ),
      );
    }

    _controller = controller;
  }

  Future<void> callJs(String functionCall) async {
    await _controller.runJavaScript(functionCall);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
