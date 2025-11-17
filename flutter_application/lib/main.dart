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
import 'package:flutter/material.dart';
import '../maldong_avatar.dart';

const femaleAvatarUrl =
    'https://models.readyplayer.me/690d8484132e61458cf8e667.glb';
const maleAvatarUrl =
    'https://models.readyplayer.me/690d81ec37697c47c8a85f69.glb';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null); // ✅ 한국 로케일 날짜 데이터 로드
  Intl.defaultLocale = 'ko_KR'; // ✅ 기본 로케일을 한국어로
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

          // ✅ 여기서 전체 텍스트 배율을 한 번에 조정
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaleFactor: fontProvider.fontScale, // 🔥 글자 전체 배율 적용
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
          onStartCall: _startCall, // ✅ 여기서 영상통화 시작 콜백 전달
        );

      case AppScreen.videocall:
        return VideoCallScreen(
          onEndCall: _endCall, // ✅ 통화 종료 콜백
        );

      case AppScreen.settings:
        return SettingsScreen(
          onBack: _goToHome,
          onLogout: _logout,
        );
    }
  }
}
