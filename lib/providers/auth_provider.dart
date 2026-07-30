import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { teacher, other, none }

class AuthProvider with ChangeNotifier {
  UserRole _role = UserRole.none;
  bool _isInitialized = false;

  UserRole get role => _role;
  bool get isLoggedIn => _role != UserRole.none;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('user_role');
    if (savedRole == 'teacher') {
      _role = UserRole.teacher;
    } else if (savedRole == 'other') {
      _role = UserRole.other;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String password) async {
    UserRole newRole = UserRole.none;
    if (password == 'SVCT123') {
      newRole = UserRole.teacher;
    } else if (password == 'SVC123') {
      newRole = UserRole.other;
    }

    if (newRole != UserRole.none) {
      _role = newRole;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', newRole == UserRole.teacher ? 'teacher' : 'other');
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _role = UserRole.none;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    notifyListeners();
  }
}
