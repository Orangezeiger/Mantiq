import 'package:shared_preferences/shared_preferences.dart';

// Speichert den eingeloggten Nutzer lokal auf dem Geraet
class AuthService {

  static Future<void> saveUser(int userId, String email, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('email', email);
    await prefs.setString('displayName', displayName);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final email  = prefs.getString('email');
    if (userId == null || email == null) return null;
    return {
      'userId':      userId,
      'email':       email,
      'displayName': prefs.getString('displayName') ?? '',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('email');
  }
}
