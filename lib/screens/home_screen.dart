import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_panel_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return user.role == "ADMIN" ? const AdminPanelScreen() : const MapScreen();
  }
}
