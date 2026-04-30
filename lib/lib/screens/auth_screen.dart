import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const VaronApp());
}

class VaronApp extends StatelessWidget {
  const VaronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Varón',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool loading = false;

  // LOGIN
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // SIGNUP
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final signupEmailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final signupPassCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  void toggle(bool login) {
    setState(() => isLogin = login);
  }

  // ---------------- LOGIN ----------------
  Future<void> login() async {
    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse("http://YOUR_BACKEND/login"),
        body: {
          "email": emailCtrl.text,
          "password": passCtrl.text,
        },
      );

      if (res.statusCode == 200) {
        showMsg("Welcome back to Varón", true);
      } else {
        showMsg("Invalid credentials", false);
      }
    } catch (e) {
      showMsg("Network error", false);
    }

    setState(() => loading = false);
  }

  // ---------------- SIGNUP ----------------
  Future<void> signup() async {
    if (signupPassCtrl.text != confirmCtrl.text) {
      showMsg("Passwords do not match", false);
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse("http://YOUR_BACKEND/signup"),
        body: {
          "firstName": firstCtrl.text,
          "lastName": lastCtrl.text,
          "email": signupEmailCtrl.text,
          "phone": phoneCtrl.text,
          "password": signupPassCtrl.text,
        },
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        showMsg("Account created successfully", true);
      } else {
        showMsg(data["message"] ?? "Signup failed", false);
      }
    } catch (e) {
      showMsg("Network error", false);
    }

    setState(() => loading = false);
  }

  void showMsg(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xfff5f7fa),
              Color(0xffc3cfe2),
            ],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BRAND
                const Text(
                  "Varón",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Georgia',
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 20),

                // CARD
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 25,
                        color: Colors.black12,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // TABS (Varón style)
                      Container(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: _tab("Login", isLogin, () => toggle(true)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _tab("Sign Up", !isLogin, () => toggle(false)),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // CONTENT
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: isLogin ? _loginUI() : _signupUI(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- TAB ----------------
  Widget _tab(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? Colors.black : const Color(0xfff2f2f2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- LOGIN UI ----------------
  Widget _loginUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Enter your credentials to access your account",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        _field("Email", emailCtrl),
        const SizedBox(height: 12),
        _field("Password", passCtrl, obscure: true),

        const SizedBox(height: 22),

        _button("Login to Your Account", login),
      ],
    );
  }

  // ---------------- SIGNUP UI ----------------
  Widget _signupUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create Account",
            style: TextStyle(fontSize: 22, fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 16),

          _field("First Name", firstCtrl),
          const SizedBox(height: 10),
          _field("Last Name", lastCtrl),
          const SizedBox(height: 10),
          _field("Email", signupEmailCtrl),
          const SizedBox(height: 10),
          _field("Phone", phoneCtrl),
          const SizedBox(height: 10),
          _field("Password", signupPassCtrl, obscure: true),
          const SizedBox(height: 10),
          _field("Confirm Password", confirmCtrl, obscure: true),

          const SizedBox(height: 22),

          _button("Create Account", signup),
        ],
      ),
    );
  }

  // ---------------- INPUT FIELD ----------------
  Widget _field(String label, TextEditingController ctrl,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
      ),
    );
  }

  // ---------------- BUTTON ----------------
  Widget _button(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(loading ? "Loading..." : text),
      ),
    );
  }
}