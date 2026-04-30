import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/seller_application_service.dart';
import '../services/seller_auth_service.dart';

class SellerApplicationFormScreen extends StatefulWidget {
  const SellerApplicationFormScreen({super.key});

  @override
  State<SellerApplicationFormScreen> createState() =>
      _SellerApplicationFormScreenState();
}

class _SellerApplicationFormScreenState
    extends State<SellerApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _prefillEmail();
  }

  Future<void> _prefillEmail() async {
    final email = await AuthService.getUserEmail();
    if (email != null && mounted) {
      _emailCtrl.text = email;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _fullNameCtrl.dispose();
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final buyerEmail = await AuthService.getUserEmail();

    final error = await SellerAuthService.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      storeName: _storeNameCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFF0A0A0A),
          behavior: SnackBarBehavior.floating,
          shape:
              const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Auto-approve: set the buyer's role to seller immediately
    if (buyerEmail != null) {
      await SellerApplicationService.syncRole(
          buyerEmail, SellerApplicationService.roleSeller);
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_submitted),
          icon: const Icon(Icons.arrow_back_ios,
              size: 16, color: Color(0xFF0A0A0A)),
        ),
        title: const Text(
          'BECOME A SELLER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Color(0xFF0A0A0A),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              color: const Color(0xFF0A0A0A),
              child: const Icon(Icons.storefront_outlined,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 28),
            const Text(
              'SELLER ACCOUNT CREATED',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Color(0xFF0A0A0A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your seller account is now active. You can access the seller '
              'portal using your registered email and password.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                ),
                child: const Text(
                  'GO TO PROFILE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create your seller account on Varón and start selling to '
              'thousands of customers.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.7,
              ),
            ),
            const SizedBox(height: 32),

            // ── Seller Login Credentials ──────────────────────────────────
            _sectionLabel('SELLER LOGIN CREDENTIALS'),
            const SizedBox(height: 4),
            const Text(
              'Use these to sign in to the Seller Portal.',
              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
            const SizedBox(height: 16),
            _field(
              label: 'EMAIL ADDRESS',
              controller: _emailCtrl,
              hint: 'seller@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _field(
              label: 'PASSWORD',
              controller: _passwordCtrl,
              hint: 'Min. 6 characters',
              obscure: _obscurePass,
              onToggleObscure: () =>
                  setState(() => _obscurePass = !_obscurePass),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _field(
              label: 'CONFIRM PASSWORD',
              controller: _confirmPassCtrl,
              hint: 'Re-enter password',
              obscure: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // ── Store Information ─────────────────────────────────────────
            _sectionLabel('STORE INFORMATION'),
            const SizedBox(height: 16),
            _field(
              label: 'STORE NAME',
              controller: _storeNameCtrl,
              hint: 'Your shop name as displayed to buyers',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Store name is required' : null,
            ),

            const SizedBox(height: 32),

            // ── Personal Information ──────────────────────────────────────
            _sectionLabel('PERSONAL INFORMATION'),
            const SizedBox(height: 16),
            _field(
              label: 'FULL NAME',
              controller: _fullNameCtrl,
              hint: 'e.g. Juan dela Cruz',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
            ),
            const SizedBox(height: 16),
            _field(
              label: 'ADDRESS',
              controller: _addressCtrl,
              hint: 'Street, City, Province',
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),
            _field(
              label: 'PHONE NUMBER',
              controller: _phoneCtrl,
              hint: 'e.g. 09XXXXXXXXX',
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                if (v.trim().length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),

            const SizedBox(height: 40),
            Container(height: 1, color: const Color(0xFFEEEEEE)),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  disabledBackgroundColor: const Color(0xFFCCCCCC),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CREATE SELLER ACCOUNT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 24, height: 1, color: const Color(0xFF0A0A0A)),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0A0A0A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            suffixIcon: onToggleObscure != null
                ? GestureDetector(
                    onTap: onToggleObscure,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
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
                const BoxConstraints(minWidth: 44, minHeight: 44),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
