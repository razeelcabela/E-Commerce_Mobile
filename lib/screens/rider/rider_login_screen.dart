import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../services/rider_auth_service.dart';

class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _snack('Please fill in all fields');
      return;
    }

    setState(() => _loading = true);

    try {
      developer.log('[RIDER_LOGIN] Attempting login for: $email');
      final error = await RiderAuthService.login(email: email, password: pass);

      if (!mounted) return;
      setState(() => _loading = false);

      if (error != null) {
        developer.log('[RIDER_LOGIN] Login error: $error');
        _snack(error);
      } else {
        developer.log('[RIDER_LOGIN] Login successful, navigating to dashboard');
        Navigator.of(context).pushReplacementNamed('/rider/dashboard');
      }
    } catch (e, stackTrace) {
      developer.log('[RIDER_LOGIN] UNEXPECTED ERROR: $e');
      developer.log('[RIDER_LOGIN] STACK: $stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('An error occurred during login: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF0A0A0A),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 0, vertical: 48),
          child: SizedBox(
            width: 420,
            child: Column(
              children: [
                const Text(
                  'VARÓN',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'RIDER PORTAL',
                  style: TextStyle(
                      fontSize: 8,
                      color: Color(0xFF999999),
                      letterSpacing: 4),
                ),
                const SizedBox(height: 48),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SIGN IN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                          width: 24,
                          height: 1.5,
                          color: const Color(0xFF0A0A0A)),
                      const SizedBox(height: 32),
                      Container(height: 1, color: const Color(0xFFEEEEEE)),
                      const SizedBox(height: 32),
                      _field('EMAIL ADDRESS', _emailCtrl,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),
                      _field('PASSWORD', _passCtrl,
                          obscure: _obscurePass,
                          onToggle: () => setState(
                              () => _obscurePass = !_obscurePass)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            disabledBackgroundColor:
                                const Color(0xFF888888),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Back to buyer login',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: const Color(0xFFF6F6F6),
                        child: const Text(
                          'No account yet? Apply as a rider from the '
                          'buyer profile section in the app.',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                              height: 1.6),
                          textAlign: TextAlign.center,
                        ),
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 8),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1)),
            focusedBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color(0xFF0A0A0A), width: 1.5)),
            suffixIcon: onToggle != null
                ? GestureDetector(
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ),
      ],
    );
  }
}
