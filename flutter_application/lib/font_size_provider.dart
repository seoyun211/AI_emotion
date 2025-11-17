import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption {
  normal('보통', 1.0),
  large('크게', 1.2),
  extraLarge('아주 크게', 1.4);

  final String label;
  final double scale;

  const FontSizeOption(this.label, this.scale);
}

class FontSizeProvider extends ChangeNotifier {
  FontSizeOption _currentFontSize = FontSizeOption.normal;
  static const String _fontSizeKey = 'font_size_setting';

  FontSizeOption get currentFontSize => _currentFontSize;
  double get fontScale => _currentFontSize.scale;

  FontSizeProvider() {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_fontSizeKey) ?? 0;
    _currentFontSize = FontSizeOption.values[savedIndex];
    notifyListeners();
  }

  Future<void> setFontSize(FontSizeOption size) async {
    _currentFontSize = size;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontSizeKey, size.index);
  }
}