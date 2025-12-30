import 'package:flutter/material.dart';
import 'login_service.dart';

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
      // Login with Firestore
      _userData = await _loginService.login(userId, password);
      
      // Make sure the userId is stored for later use
      if (!_userData!.containsKey('userId')) {
        _userData!['userId'] = userId;
      }
      
      _state = LoginState.success;
    } catch (e) {
      _state = LoginState.error;
      
      // Clean up the error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      
      _errorMessage = errorMsg;
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