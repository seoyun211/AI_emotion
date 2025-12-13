// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:camera/camera.dart';

import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/guardian/guardian_home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/video_call_screen.dart';
import 'font_size_provider.dart';
import 'maldong_avatar.dart';
import 'package:camera/camera.dart';

// GLB 파일 경로
const customAvatarUrl = 'assets/model.glb';

// 앱 전체에서 쓸 카메라 리스트
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 🔴 카메라 초기화에 try-catch 적용
  try {
    cameras = await availableCameras();
    print('✅ 카메라 목록 로드 성공: ${cameras.length}개');
  } on CameraException catch (e) {
    // 카메라 초기화 실패 시 빈 리스트로 초기화하고 오류 메시지 출력
    cameras = [];
    print('🚨 카메라 초기화 실패 (CameraException): ${e.code} - ${e.description}');
    print('다른 프로그램이 카메라를 사용 중이거나 권한 문제일 수 있습니다.');
  } catch (e) {
    // 기타 예상치 못한 오류 처리
    cameras = [];
    print('🚨 카메라 초기화 중 예상치 못한 오류 발생: $e');
  }

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

          // 한글 로케일 설정 추가
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
          ],
          locale: const Locale('ko', 'KR'),

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
  signup,
  login,
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
  
  // ✅ 로그인 정보 저장
  int? _userId;
  String? _accessToken;
  String? _username;

  // 통합 회원가입 화면으로 이동
  void _goToSignUp() {
    setState(() {
      _currentScreen = AppScreen.signup;
    });
  }

  // 통합 로그인 화면으로 이동
  void _goToLogin() {
    setState(() {
      _currentScreen = AppScreen.login;
    });
  }

  // 회원가입 성공 후 (role에 따라 로그인 화면으로)
  void _handleSignUpSuccess(String role) {
    // role: 'ward' (어르신) 또는 'guardian' (보호자)
    setState(() {
      _userType = role == 'ward' ? UserType.elderly : UserType.guardian;
      _currentScreen = AppScreen.login; // 회원가입 후 로그인 화면으로
    });
  }

  // ✅ 로그인 성공 (로그인 정보를 모두 받아서 저장)
  void _handleLoginSuccess(Map<String, dynamic> loginData) {
    // loginData: {
    //   'user_id': int,
    //   'access_token': String,
    //   'role': String,
    //   'username': String
    // }
    
    final String role = loginData['role'];
    
    setState(() {
      _isLoggedIn = true;
      _userId = loginData['user_id'];
      _accessToken = loginData['access_token'];
      _username = loginData['username'];
      _userType = role == 'ward' ? UserType.elderly : UserType.guardian;

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
      _userId = null;
      _accessToken = null;
      _username = null;
      _currentScreen = AppScreen.welcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.welcome:
        return WelcomeScreen(
          onGoToSignUp: _goToSignUp,
          onGoToLogin: _goToLogin,
        );

      case AppScreen.signup:
        return SignUpScreen(
          onSignUpSuccess: _handleSignUpSuccess,
        );

      case AppScreen.login:
        return LoginScreen(
          onLoginSuccess: _handleLoginSuccess,
        );

      case AppScreen.elderlyHome:
        return HomeScreen(
          onOpenSettings: _goToSettings,
          onStartCall: _startCall,
          avatar: MaldongAvatar(url: customAvatarUrl),
        );

      case AppScreen.guardianHome:
        // ✅ 필수 파라미터 전달
        if (_userId == null || _accessToken == null) {
          // 로그인 정보가 없으면 로그인 화면으로
          return LoginScreen(
            onLoginSuccess: _handleLoginSuccess,
          );
        }
        return GuardianHomeScreen(
          guardianUserId: _userId!,
          accessToken: _accessToken!,
          onOpenSettings: _goToSettings,
          onLogout: _logout,
        );

      case AppScreen.videocall:
        // ✅ 로그인 정보가 없으면 로그인 화면으로
        if (_userId == null || _accessToken == null) {
          return LoginScreen(
            onLoginSuccess: _handleLoginSuccess,
          );
        }
        return VideoCallScreen(
          onEndCall: _endCall,
          avatar: MaldongAvatar(url: customAvatarUrl),
          userId: _userId!,  // ✅ 추가
          accessToken: _accessToken!,  // ✅ 추가
        );

      case AppScreen.settings:
        return SettingsScreen(
          onBack: _goToHome,
          onLogout: _logout,
        );
    }
  }
}