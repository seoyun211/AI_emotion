import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class MaldongAvatar extends StatelessWidget {
  final String avatarUrl;

  const MaldongAvatar({
    super.key,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: avatarUrl,
      alt: '말동이 아바타',

      // 🔹 회전/줌 못 하게 막기 (항상 정면)
      cameraControls: false,
      disableTap: true,

      // 🔹 자동 회전 끄기 → 옆으로 안 돌아감
      autoRotate: false,

      // 🔹 배경은 투명 (뒤에 우리가 깔아둔 그라디언트/검정색 보이게)
      backgroundColor: Colors.transparent,

      // 🔹 카메라 세팅 (얼굴 클로즈업)
      // 형식: '가로각도 세로각도 거리'
      // 0deg 90deg 0.35m → 정면, 약간 위에서, 아주 가까이
      cameraOrbit: '0deg 90deg 0.35m',

      // 모델의 어느 높이를 중심으로 볼지 (머리 쪽으로 올리기)
      // 1.6m 정도면 머리/목 근처
      cameraTarget: '0m 1.6m 0m',

      // 화각: 숫자 줄일수록 더 줌인
      fieldOfView: '15deg',
    );
  }
}
