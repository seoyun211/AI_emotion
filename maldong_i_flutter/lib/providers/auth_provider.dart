import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _user;
  String? _token;
  bool _loading = true;

  String? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('guardian_token');
      
      if (storedToken != null) {
        _token = storedToken;
        await _fetchUserInfo(storedToken);
      }
    } catch (error) {
      if (kDebugMode) {
        print('Token load failed: $error');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserInfo(String userToken) async {
    try {
      // TODO: API 서비스 연동
      // final userInfo = await ApiService().getMyInfo(userToken);
      // _user = userInfo;
    } catch (error) {
      if (kDebugMode) {
        print('User info fetch failed: $error');
      }
      await _logout();
    }
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      // TODO: API 서비스 연동
      // final result = await ApiService().login(phone, password);
      
      // if (result['access_token'] != null) {
      //   final prefs = await SharedPreferences.getInstance();
      //   await prefs.setString('guardian_token', result['access_token']);
      //   _token = result['access_token'];
      //   await _fetchUserInfo(result['access_token']);
      //   return {'success': true};
      // }
      
      return {'success': false, 'error': '로그인 실패'};
    } catch (error) {
      if (kDebugMode) {
        print('Login failed: $error');
      }
      return {'success': false, 'error': '로그인 실패'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> guardianData) async {
    try {
      // TODO: API 서비스 연동
      // final result = await ApiService().register(guardianData);
      // return {'success': true, 'data': result};
      
      return {'success': false, 'error': '회원가입 실패'};
    } catch (error) {
      if (kDebugMode) {
        print('Registration failed: $error');
      }
      return {'success': false, 'error': '회원가입 실패'};
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guardian_token');
      _token = null;
      _user = null;
      notifyListeners();
    } catch (error) {
      if (kDebugMode) {
        print('Logout failed: $error');
      }
    }
  }

  // useAuth() 훅 대신에 이렇게 사용
  static AuthProvider of(BuildContext context) {
    return Provider.of<AuthProvider>(context, listen: true);
  }
}