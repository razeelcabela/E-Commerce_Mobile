import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/seller_application.dart';
import '../../services/seller_application_service.dart';
import '../../services/auth_service.dart';

class SellerApplicationFormScreen extends StatefulWidget {
  const SellerApplicationFormScreen({super.key});

  @override
  State<SellerApplicationFormScreen> createState() =>
      _SellerApplicationFormScreenState();
}

class _SellerApplicationFormScreenState
    extends State<SellerApplicationFormScreen> {
  final _fullNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _validIdNoteCtrl = TextEditingController();

  bool _agreedToTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _validIdNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_validateForm()) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final userEmail = await AuthService.getUserEmail();
    if (userEmail == null) {
      setState(() => _loading = false);
      _snack('Error: Unable to retrieve user email');
      return;
    }

    final application = SellerApplication(
      id: const Uuid().v4(),
      userEmail: userEmail,
      fullName: _fullNameCtrl.text.trim(),
      businessName: _businessNameCtrl.text.trim().isEmpty
          ? null
          : _businessNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      validIdNote: _validIdNoteCtrl.text.trim().isEmpty
          ? null
          : _validIdNoteCtrl.text.trim(),
      status: SellerApplication.pending,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await SellerApplicationService.submit(application);

      if (!mounted) return;
      _snack('Application submitted successfully!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _loading = false);
      _snack('Error submitting application: $e');
    }
  }

  bool _validateForm() {
    if (_fullNameCtrl.text.isEmpty) {
      _snack('Please enter your full name');
      return false;
    }
    if (_addressCtrl.text.isEmpty) {
      _snack('Please enter your address');
      return false;
    }
    if (_phoneCtrl.text.isEmpty) {
      _snack('Please enter your phone number');
      return false;
    }
    if (!_agreedToTerms) {
      _snack('Please agree to the terms and conditions');
      return false;
    }
    return true;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF0A0A0A),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
        ),
        title: const Text(
          'APPLY AS SELLER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open Your Store',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Become a seller and start your journey with us. Fill out the form below to apply.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                _buildTextField(
                  label: 'FULL NAME *',
                  controller: _fullNameCtrl,
                  hint: 'Enter your full name',
                ),
                const SizedBox(height: 20),

                // Business Name
                _buildTextField(
                  label: 'BUSINESS NAME',
                  controller: _businessNameCtrl,
                  hint: 'Name of your store or business',
                ),
                const SizedBox(height: 20),

                // Phone Number
                _buildTextField(
                  label: 'PHONE NUMBER *',
                  controller: _phoneCtrl,
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Address
                _buildTextField(
                  label: 'ADDRESS *',
                  controller: _addressCtrl,
                  hint: 'Enter your business address',
                  minLines: 2,
                ),
                const SizedBox(height: 20),

                // Valid ID Note
                _buildTextField(
                  label: 'VALID ID INFORMATION',
                  controller: _validIdNoteCtrl,
                  hint: 'Provide details about your valid ID (optional)',
                  minLines: 2,
                ),
                const SizedBox(height: 28),

                // Terms Checkbox
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() =>
                                    _agreedToTerms = value ?? false);
                              },
                              fillColor: WidgetStateProperty.resolveWith(
                                (states) => states
                                        .contains(WidgetState.selected)
                                    ? const Color(0xFF0A0A0A)
                                    : Colors.white,
                              ),
                              side: const BorderSide(
                                color: Color(0xFF0A0A0A),
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'I agree to the Terms and Conditions',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0A0A0A),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'By applying, you agree to our seller policies, conduct standards, and commission terms.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF888888),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFF888888),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'SUBMIT APPLICATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: const Color(0xFFF6F6F6),
                  child: const Text(
                    'Your application will be reviewed by our team within 2-3 business days. '
                    'You\'ll receive an email once your store is approved and ready to go live.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF666666),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int minLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          color: Colors.white,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFFBBBBBB),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF0A0A0A),
                  width: 1,
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0A0A0A),
            ),
          ),
        ),
      ],
    );
  }
}
