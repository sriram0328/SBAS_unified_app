import 'package:flutter/material.dart';
import 'login_service.dart';
import '../../core/session.dart';

enum LoginState { initial, loading, success, error }

class LoginController extends ChangeNotifier {
  final LoginService _loginService = LoginService();

  LoginState _state = LoginState.initial;
  LoginState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  Future<void> login(String userId, String password) async {
    _state = LoginState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _userData = await _loginService.login(userId, password);

      if (_userData!['role'] == 'faculty') {
        Session.facultyId = _userData!['facultyId'];
      }

      if (!_userData!.containsKey('userId')) {
        _userData!['userId'] = userId;
      }

      _state = LoginState.success;
    } catch (e) {
      _state = LoginState.error;

      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.replaceFirst('Exception: ', '');
      }
      _errorMessage = msg;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _state = LoginState.initial;
    _errorMessage = null;
    _userData = null;
    notifyListeners();
  }
}
