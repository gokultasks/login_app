import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class StorageRepository {
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  
  Future<void> saveSession({
    required String userId,
    required String userEmail,
    String? profileImagePath,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserId, userId);
    await prefs.setString(AppConstants.keyUserEmail, userEmail);
    if (profileImagePath != null) {
      await prefs.setString(AppConstants.keyProfileImagePath, profileImagePath);
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  Future<String?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.keyUserId);
  }

  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.keyUserEmail);
  }

  Future<String?> getProfileImagePath() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.keyProfileImagePath);
  }

  Future<void> saveProfileImagePath(String path) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConstants.keyProfileImagePath, path);
  }

  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  
  Future<void> saveString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  Future<void> remove(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }
}
