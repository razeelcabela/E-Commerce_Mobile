import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0: email, 1: OTP, 2: new password
  String _email = '';

  final _emailCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCooldown(int seconds) {
    setState(() => _resendCountdown = seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 1) {
        t.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  String get _otp => _otpCtrls.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Please enter your email address');
      return;
    }
    setState(() => _loading = true);
    final error = await AuthService.sendPasswordResetOtp(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      _snack(error);
      return;
    }
    _email = email;
    setState(() => _step = 1);
    _startResendCooldown(60);
  }

  Future<void> _verifyOtp() async {
    if (_loading || _otp.length < 6) return;
    setState(() => _loading = true);
    final error = await AuthService.verifyPasswordResetOtp(
        email: _email, token: _otp);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      _snack(error);
      for (final c in _otpCtrls) {
        c.clear();
      }
      _otpNodes[0].requestFocus();
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _snack('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    final error = await AuthService.updatePassword(_newPassCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      _snack(error);
      return;
    }
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A2F),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.check,
                  color: Color(0xFF4CAF50), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Password Reset!',
              style: GoogleFonts.commissioner(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your password has been successfully updated. Please log in with your new password.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF888888),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (_) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A0A0A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'GO TO LOGIN',
                  style: GoogleFonts.commissioner(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: const Color(0xFF0A0A0A),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 48),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _step == 0
                    ? _emailStep()
                    : _step == 1
                        ? _otpStep()
                        : _newPasswordStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailStep() {
    return Column(
      key: const ValueKey('email_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORGOT\nPASSWORD',
          style: GoogleFonts.commissioner(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter your email address and we\'ll send you a 6-digit code to reset your password.',
          style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF888888),
              height: 1.6),
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style:
              GoogleFonts.inter(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Email address',
            labelStyle: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF666666)),
            floatingLabelStyle: GoogleFonts.commissioner(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1,
            ),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A0A0A),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF0A0A0A)),
                  )
                : Text(
                    'SEND CODE',
                    style: GoogleFonts.commissioner(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      key: const ValueKey('otp_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENTER\nVERIFICATION\nCODE',
          style: GoogleFonts.commissioner(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Code sent to',
          style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF888888)),
        ),
        const SizedBox(height: 4),
        Text(
          _email,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46,
              height: 56,
              child: TextField(
                controller: _otpCtrls[i],
                focusNode: _otpNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                style: GoogleFonts.commissioner(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF2A2A2A), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Colors.white, width: 1.5),
                  ),
                ),
                onChanged: (v) {
                  if (v.length == 1 && i < 5) {
                    _otpNodes[i + 1].requestFocus();
                  }
                  if (v.isEmpty && i > 0) {
                    _otpNodes[i - 1].requestFocus();
                  }
                  if (_otp.length == 6) _verifyOtp();
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A0A0A),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF0A0A0A)),
                  )
                : Text(
                    'VERIFY CODE',
                    style: GoogleFonts.commissioner(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _resendCountdown == 0
                ? () async {
                    setState(() => _loading = true);
                    await AuthService.sendPasswordResetOtp(_email);
                    if (mounted) {
                      setState(() => _loading = false);
                      _startResendCooldown(60);
                    }
                  }
                : null,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF666666)),
                children: [
                  const TextSpan(text: "Didn't receive a code? "),
                  TextSpan(
                    text: _resendCountdown > 0
                        ? 'Resend in ${_resendCountdown}s'
                        : 'Resend',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _resendCountdown > 0
                          ? const Color(0xFF444444)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _newPasswordStep() {
    return Column(
      key: const ValueKey('password_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SET NEW\nPASSWORD',
          style: GoogleFonts.commissioner(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter a new password for your account.',
          style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF888888),
              height: 1.6),
        ),
        const SizedBox(height: 48),
        _darkField(
          'New password',
          _newPassCtrl,
          obscure: _obscureNew,
          onToggle: () =>
              setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 20),
        _darkField(
          'Confirm new password',
          _confirmPassCtrl,
          obscure: _obscureConfirm,
          onToggle: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A0A0A),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF0A0A0A)),
                  )
                : Text(
                    'RESET PASSWORD',
                    style: GoogleFonts.commissioner(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _darkField(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF666666)),
        floatingLabelStyle: GoogleFonts.commissioner(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1,
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.white, width: 1.5),
        ),
        suffixIcon: onToggle != null
            ? IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF666666),
                ),
              )
            : null,
      ),
    );
  }
}
