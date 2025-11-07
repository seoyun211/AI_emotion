import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seedColor = Color(0xFFFFA726); // amber 계열

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    useMaterial3: true,
    scaffoldBackgroundColor: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFF3E0), // amber-50 비슷
        Color(0xFFFFE0B2), // orange-100 비슷
      ],
    ).createShader(const Rect.fromLTWH(0, 0, 1, 1)) == null
        ? Colors.white
        : null,
    fontFamily: 'Roboto',
  );
}
