import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/video_call_screen.dart';
import 'font_size_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../maldong_avatar.dart';

// GLB 파일 경로 (Fauxtolabs 모델)
const customAvatarUrl = 'assets/model.glb';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  Intl.defaultLocale = 'ko_KR';
  runApp(
    ChangeNotifierProvider(
      create: (context) => FontSizeProvider(),
      child: const MalDongApp(),
    ),
  );
}

class MalDongApp extends StatelessWidget {
  const MalDongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return MaterialApp(
          title: '말동',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaleFactor: fontProvider.fontScale,
              ),
              child: child!,
            );
          },
          home: const _AppRoot(),
        );
      },
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
  bool _isInCall = false;

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
          onStartCall: _startCall,
          avatar: MaldongAvatar(url: customAvatarUrl),
        );

      case AppScreen.videocall:
        return VideoCallScreen(
          onEndCall: _endCall,
          avatar: MaldongAvatar(url: customAvatarUrl),
        );

      case AppScreen.settings:
        return SettingsScreen(
          onBack: _goToHome,
          onLogout: _logout,
        );
    }
  }
}
