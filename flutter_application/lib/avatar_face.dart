import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class AvatarFace extends StatelessWidget {
  final String avatarUrl;

  const AvatarFace({
    super.key,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: avatarUrl,
      alt: '3D 아바타',

      // 🔹 화면에서 고정된 표정/포즈로 보이게 (사용자 제어 X)
      cameraControls: false,
      disableTap: true,

      // 🔹 카메라가 빙글빙글 돌지 않도록
      autoRotate: false,

      // 🔹 GLB 안에 있는 애니메이션 자동 재생 (RobotExpressive는 애니메이션 있음)
      autoPlay: true,

      // 🔹 배경은 투명 → 뒤에 우리가 깔아둔 배경 이미지가 보이게
      backgroundColor: Colors.transparent,

      // 🔹 카메라 세팅 (아바타 상반신 정도 보이게)
      // 거리/시야각은 나중에 맞춰가면 됨
      cameraOrbit: '0deg 90deg 2m', // (각도, 각도, 거리)
      cameraTarget: '0m 1.5m 0m', // (x, y, z) → y가 높이
      fieldOfView: '25deg', // 숫자 줄이면 더 줌인됨
    );
  }
}
