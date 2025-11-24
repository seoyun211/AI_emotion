// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:camera/camera.dart';

import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/elderly/elderly_signup_screen.dart';
import 'screens/elderly/elderly_login_screen.dart';
import 'screens/guardian/guardian_signup_screen.dart';
import 'screens/guardian/guardian_login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/guardian/guardian_home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/video_call_screen.dart';
import 'font_size_provider.dart';
import 'maldong_avatar.dart';

// GLB 파일 경로
const customAvatarUrl = 'assets/model.glb';

// 앱 전체에서 쓸 카메라 리스트
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 기기 카메라 목록 미리 가져오기
  cameras = await availableCameras();

  // 한국어 날짜 로케일 설정
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
          home: const AppRoot(),
        );
      },
    );
  }
}

enum AppScreen {
  welcome,
  elderlyLogin,
  elderlySignup,
  guardianLogin,
  guardianSignup,
  elderlyHome,
  guardianHome,
  videocall,
  settings
}

enum UserType { elderly, guardian }

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppScreen _currentScreen = AppScreen.welcome;
  UserType? _userType;
  bool _isLoggedIn = false;
  bool _isInCall = false;

  // 어르신 회원가입
  void _goToElderlySignUp() {
    setState(() {
      _userType = UserType.elderly;
      _currentScreen = AppScreen.elderlySignup;
    });
  }

  // 어르신 로그인
  void _goToElderlyLogin() {
    setState(() {
      _userType = UserType.elderly;
      _currentScreen = AppScreen.elderlyLogin;
    });
  }

  // 보호자 회원가입
  void _goToGuardianSignUp() {
    setState(() {
      _userType = UserType.guardian;
      _currentScreen = AppScreen.guardianSignup;
    });
  }

  // 보호자 로그인
  void _goToGuardianLogin() {
    setState(() {
      _userType = UserType.guardian;
      _currentScreen = AppScreen.guardianLogin;
    });
  }

  // 로그인 성공
  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
      if (_userType == UserType.elderly) {
        _currentScreen = AppScreen.elderlyHome;
      } else {
        _currentScreen = AppScreen.guardianHome;
      }
    });
  }

  void _goToSettings() {
    setState(() {
      _currentScreen = AppScreen.settings;
    });
  }

  void _goToHome() {
    setState(() {
      if (_userType == UserType.elderly) {
        _currentScreen = AppScreen.elderlyHome;
      } else {
        _currentScreen = AppScreen.guardianHome;
      }
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
      _currentScreen = AppScreen.elderlyHome;
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _userType = null;
      _currentScreen = AppScreen.welcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.welcome:
        return WelcomeScreen(
          onGoToElderlySignUp: _goToElderlySignUp,
          onGoToElderlyLogin: _goToElderlyLogin,
          onGoToGuardianSignUp: _goToGuardianSignUp,
          onGoToGuardianLogin: _goToGuardianLogin,
        );

      case AppScreen.elderlyLogin:
        return ElderlyLoginScreen(
          onLoginSuccess: _handleLoginSuccess,
        );

      case AppScreen.elderlySignup:
        return ElderlySignUpScreen(
          onSignUpSuccess: _goToElderlyLogin,
        );

      case AppScreen.guardianLogin:
        return GuardianLoginScreen(
          onLoginSuccess: _handleLoginSuccess,
        );

      case AppScreen.guardianSignup:
        return GuardianSignUpScreen(
          onSignUpSuccess: _goToGuardianLogin,
        );

      case AppScreen.elderlyHome:
        return HomeScreen(
          onOpenSettings: _goToSettings,
          onStartCall: _startCall,
          avatar: MaldongAvatar(url: customAvatarUrl),
        );

      case AppScreen.guardianHome:
        return GuardianHomeScreen(
          onOpenSettings: _goToSettings,
          onLogout: _logout,
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