import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class MaldongAvatar extends StatelessWidget {
  final String url;

  const MaldongAvatar({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: ModelViewer(
        src: url, // GLB 모델 경로
        autoPlay: true, // 모델 내 애니메이션 자동 재생
        autoRotate: false, // 회전 가능
        cameraControls: true, // 터치/마우스로 회전/확대 가능
      ),
    );
  }
}
