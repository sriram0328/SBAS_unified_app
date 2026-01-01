import 'package:flutter/material.dart';
import 'login_service.dart';
import '../../core/session.dart'; // ✅ GLOBAL SESSION STORAGE

enum LoginState { initial, loading, success, error }

class LoginController extends ChangeNotifier {
  final LoginService _loginService = LoginService();

  LoginState _state = LoginState.initial;
  LoginState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  /// 🔐 Unified Login (Student / Faculty)
  Future<void> login(String userId, String password) async {
    _state = LoginState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // ----------------------------------
      // 🔹 LOGIN VIA LOGIN SERVICE
      // ----------------------------------
      _userData = await _loginService.login(userId, password);

      // ----------------------------------
      // 🔥 STORE FACULTY ID FOR ATTENDANCE
      // ----------------------------------
      if (_userData!['role'] == 'faculty') {
        Session.facultyId = _userData!['facultyId'];
        debugPrint('✅ Session.facultyId set = ${Session.facultyId}');
      }

      // ----------------------------------
      // 🔹 ENSURE userId IS PRESENT
      // ----------------------------------
      if (!_userData!.containsKey('userId')) {
        _userData!['userId'] = userId;
      }

      _state = LoginState.success;

    } catch (e) {
      _state = LoginState.error;

      // Clean error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }

      _errorMessage = errorMsg;
    } finally {
      notifyListeners();
    }
  }

  /// 🔄 Reset login state
  void reset() {
    _state = LoginState.initial;
    _errorMessage = null;
    _userData = null;
    notifyListeners();
  }
}
