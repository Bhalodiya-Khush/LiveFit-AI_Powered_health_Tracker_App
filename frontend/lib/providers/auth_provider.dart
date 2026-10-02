import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _api.token != null;

  int get age => _user?['age'] ?? 24;
  double get weight => (_user?['weight'] as num?)?.toDouble() ?? 70.0;
  double get height => (_user?['height'] as num?)?.toDouble() ?? 175.0;
  String get healthHurdles => _user?['healthHurdles'] ?? 'none';
  int get dailyStepGoal => _user?['dailyStepGoal'] ?? 10000;
  int get dailyCalorieGoal => _user?['dailyCalorieGoal'] ?? 2200;
  double get dailySleepGoal => (_user?['dailySleepGoal'] as num?)?.toDouble() ?? 8.0;

  Future<void> initAuth() async {
    _isInitializing = true;
    notifyListeners();

    await _api.init();
    if (_api.token != null) {
      try {
        _user = await _api.getProfile();
      } catch (e) {
        debugPrint('Auto-login session expired: $e');
        await _api.logout();
        _user = null;
      }
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.login(email: email, password: password);
      _user = res['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String birthDate,
    String gender = 'male',
    double height = 175,
    double weight = 70,
    String healthHurdles = 'none',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.register(
        name: name,
        email: email,
        password: password,
        birthDate: birthDate,
        gender: gender,
        height: height,
        weight: weight,
        healthHurdles: healthHurdles,
      );
      _user = res['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _api.updateProfile(updates);
      _user = updated;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }
}
