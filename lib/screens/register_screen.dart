import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  String? error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _register() async {
    final success = await AuthService.register(
      _fullNameController.text,
      _userNameController.text,
      _emailController.text,
      _passController.text,
    );
    if (!mounted) return; // <--- context kullanmadan önce eklendi
    if (success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => error = "Kayıt başarısız!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: "Ad Soyad")),
              const SizedBox(height: 12),
              TextField(
                  controller: _userNameController,
                  decoration:
                      const InputDecoration(labelText: "Kullanıcı Adı")),
              const SizedBox(height: 12),
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "E-posta")),
              const SizedBox(height: 12),
              TextField(
                  controller: _passController,
                  decoration: const InputDecoration(labelText: "Şifre"),
                  obscureText: true),
              const SizedBox(height: 24),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                  onPressed: _register, child: const Text("Kayıt Ol")),
            ],
          ),
        ),
      ),
    );
  }
}
