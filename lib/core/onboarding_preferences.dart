import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPreferences {
  static const String _completedKey = 'onboarding_completed';
  static bool _isCompleted = false;

  static bool get isCompleted => _isCompleted;

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _isCompleted = preferences.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedKey, true);
    _isCompleted = true;
  }
}
