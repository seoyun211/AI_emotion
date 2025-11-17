// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/video_call_screen.dart';
import 'font_size_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'maldong_avatar.dart';

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
              data: mq.copyWith(textScaleFactor: fontProvider.fontScale),
              child: child!,
            );
          },
          home: AppRoot(),
        );
      },
    );
  }
}

enum AppScreen { welcome, login, signup, home, videocall, settings }

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppScreen _currentScreen = AppScreen.welcome;
  bool _isLoggedIn = false;
  bool _isInCall = false;

  void _goToSignUp() {
    setState(() {
      _currentScreen = AppScreen.signup;
    });
  }

  void _goToLogin() {
    setState(() {
      _currentScreen = AppScreen.login;
    });
  }

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
      _currentScreen = AppScreen.welcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.welcome:
        return WelcomeScreen(
          onGoToSignUp: _goToSignUp,
          onGoToLogin: _goToLogin, // 로그인 버튼 추가
        );
      case AppScreen.login:
        return LoginScreen(
          onLoginSuccess: _handleLoginSuccess,
        );
      case AppScreen.signup:
        return SignUpScreen(
          onSignUpSuccess: _goToLogin, // 회원가입 후 로그인 화면으로 이동
        );
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
        return SettingsScreen(onBack: _goToHome, onLogout: _logout);
    }
  }
}
