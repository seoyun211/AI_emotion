import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/video_call_screen.dart';

void main() {
  runApp(const MalDongApp());
}

class MalDongApp extends StatelessWidget {
  const MalDongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '말동',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppRoot(),
    );
  }
}

enum AppScreen { auth, home, videocall, settings }

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  AppScreen _currentScreen = AppScreen.auth;
  bool _isLoggedIn = false;
  bool _isInCall = false; // 나중에 필요할 수 있어서 남겨둠

  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
      _currentScreen = AppScreen.home;
    });
  }

  void _goToSettings() {
    setState(() {
      _currentScreen = AppScreen.settings;
    });
  }

  void _goToHome() {
    setState(() {
      _currentScreen = AppScreen.home;
    });
  }

  void _startCall() {
    setState(() {
      _isInCall = true;
      _currentScreen = AppScreen.videocall;
    });
  }

  void _endCall() {
    setState(() {
      _isInCall = false;
      _currentScreen = AppScreen.home;
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _currentScreen = AppScreen.auth;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.auth:
        return AuthScreen(onLoginSuccess: _handleLoginSuccess);

      case AppScreen.home:
        return HomeScreen(
          onOpenSettings: _goToSettings,
          onStartCall: _startCall,    // ✅ 여기서 영상통화 시작 콜백 전달
        );

      case AppScreen.videocall:
        return VideoCallScreen(
          onEndCall: _endCall,        // ✅ 통화 종료 콜백
        );

      case AppScreen.settings:
        return SettingsScreen(
          onBack: _goToHome,
          onLogout: _logout,
        );
    }
  }
}
