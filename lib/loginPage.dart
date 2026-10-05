import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:teknisi_aag/homepage.dart';
import 'package:teknisi_aag/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

  Future<void> loginUser(BuildContext context) async {
    final loginBox = Hive.box('loginBox');

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    /// VALIDASI INPUT
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password wajib diisi")),
      );
      return;
    }

    /// LOADING
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.login(email, password);

      Navigator.pop(context); // close loading

      /// SUCCESS LOGIN
      if (result['success'] == true) {
        final user = result['data'];

        await loginBox.put('isLoggedIn', true);
        if (user is Map && user['id'] != null) {
          await loginBox.put('id', user['id']);
        }
        await loginBox.put('name', user['name'] ?? "");
        await loginBox.put('email', user['email'] ?? "");
        await loginBox.put('level_label', user['level_label'] ?? "");
        await loginBox.put('token', user['token'] ?? "");
        await loginBox.put('photo', user['photo'] ?? "");
        await loginBox.put('job', user['job'] ?? 2);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const homePage()),
        );
      } else {
        String message = result['message'] ?? "";

        String errorText;

        if (message.toLowerCase().contains("email atau password")) {
          errorText = "Email atau password salah";
        } else if (message.toLowerCase().contains("email")) {
          errorText = "Email belum terdaftar";
        } else if (message.toLowerCase().contains("password")) {
          errorText = "Password salah";
        } else {
          errorText = message.isNotEmpty ? message : "Login gagal";
        }

        print("pesan login $message");
        showError(context, errorText);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      showError(context, "Tidak bisa terhubung ke server");
    }
  }

  void showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Gagal"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND
          SizedBox(
            width: size.width,
            height: size.height,
            child: Image.asset('assets/icons/login.png', fit: BoxFit.cover),
          ),

          Container(color: Colors.black.withOpacity(0.45)),

          /// CONTENT
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/icons/aagu.png', height: 60),

                  const SizedBox(height: 32),

                  /// EMAIL
                  _buildTextField(
                    controller: emailController,
                    hint: 'Email',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  /// PASSWORD
                  _buildTextField(
                    controller: passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// BUTTON LOGIN
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () => loginUser(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// TEXTFIELD UI
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
