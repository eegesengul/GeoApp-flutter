import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static AppUser? currentUser;

  // Giriş
  static Future<bool> login(String email, String password) async {
    final response = await ApiService.post('auth/login', {
      "email": email,
      "password": password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      ApiService.token = data['token'];
      return await getProfile();
    }
    return false;
  }

  // Kayıt
  static Future<bool> register(
      String fullName, String userName, String email, String password) async {
    final response = await ApiService.post('auth/register', {
      "fullName": fullName,
      "userName": userName,
      "email": email,
      "password": password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      ApiService.token = data['token'];
      return await getProfile();
    }
    return false;
  }

  // Profil/rol çekme
  static Future<bool> getProfile() async {
    final response = await ApiService.get('users/me');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      currentUser = AppUser.fromJson(data);
      return true;
    }
    return false;
  }
}
