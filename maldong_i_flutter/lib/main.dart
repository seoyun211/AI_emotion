// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'screens/call/call_screen.dart';
import 'screens/history/history_screen.dart';

void main() {
  runApp(const SeniorAIVideoCallApp());
}

class SeniorAIVideoCallApp extends StatelessWidget {
  const SeniorAIVideoCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 돌봄 친구',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSans',
        useMaterial3: true,
      ),
      home: const AppNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  String _currentScreen = 'home';
  bool _isCallActive = false;
  String _currentEmotion = 'neutral';

  void _setCurrentScreen(String screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  void _setIsCallActive(bool isActive) {
    setState(() {
      _isCallActive = isActive;
    });
  }

  void _setCurrentEmotion(String emotion) {
    setState(() {
      _currentEmotion = emotion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 'home':
        return HomeScreen(
          onScreenChange: _setCurrentScreen,
          onCallStatusChange: _setIsCallActive,
        );
      case 'call':
        return CallScreen(
          onScreenChange: _setCurrentScreen,
          onCallStatusChange: _setIsCallActive,
          currentEmotion: _currentEmotion,
          onEmotionChange: _setCurrentEmotion,
        );
      case 'history':
        return HistoryScreen(
          onScreenChange: _setCurrentScreen,
        );
      default:
        return HomeScreen(
          onScreenChange: _setCurrentScreen,
          onCallStatusChange: _setIsCallActive,
        );
    }
  }
}