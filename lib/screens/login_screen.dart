import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/address_service.dart';
import '../services/auth_service.dart';
// http is still used by _LocationPickerSheet for PSGC API calls

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool isLogin = true;
  bool loading = false;

  // Login
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // Signup — personal
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final signupEmailCtrl = TextEditingController();
  final signupPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // Signup — address
  final houseNumberCtrl = TextEditingController();
  final streetNameCtrl = TextEditingController();
  Map<String, String>? _selectedLocation;

  // Password visibility
  bool _obscureLogin = true;
  bool _obscureSignupPass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    firstCtrl.dispose();
    lastCtrl.dispose();
    phoneCtrl.dispose();
    signupEmailCtrl.dispose();
    signupPassCtrl.dispose();
    confirmPassCtrl.dispose();
    houseNumberCtrl.dispose();
    streetNameCtrl.dispose();
    super.dispose();
  }

  void toggle(bool login) => setState(() => isLogin = login);

  Future<void> login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => loading = true);

    final error = await AuthService.login(
      emailCtrl.text,
      passCtrl.text,
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    // Navigate to auth loading screen to determine user role
    Navigator.of(context).pushReplacementNamed('/auth-loading');
  }

  Future<void> signup() async {
    if (firstCtrl.text.isEmpty ||
        lastCtrl.text.isEmpty ||
        signupEmailCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        signupPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    if (!_emailPattern.hasMatch(signupEmailCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address')),
      );
      return;
    }
    if (signupPassCtrl.text != confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => loading = true);

    // Save user to Supabase
    final error = await AuthService.signUp(
      email: signupEmailCtrl.text,
      password: signupPassCtrl.text,
      firstName: firstCtrl.text,
      lastName: lastCtrl.text,
      phone: phoneCtrl.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    // Persist address for faster checkout (optional)
    await AddressService.saveAddress({
      'houseNumber': houseNumberCtrl.text.trim(),
      'streetName': streetNameCtrl.text.trim(),
      'barangay': _selectedLocation?['barangay'] ?? '',
      'city': _selectedLocation?['city'] ?? '',
      'province': _selectedLocation?['province'] ?? '',
      'region': _selectedLocation?['region'] ?? '',
      'barangayCode': _selectedLocation?['barangayCode'] ?? '',
      'cityCode': _selectedLocation?['cityCode'] ?? '',
      'provinceCode': _selectedLocation?['provinceCode'] ?? '',
      'regionCode': _selectedLocation?['regionCode'] ?? '',
    });

    if (!mounted) return;

    for (final c in [
      firstCtrl, lastCtrl, phoneCtrl, signupEmailCtrl,
      signupPassCtrl, confirmPassCtrl, houseNumberCtrl, streetNameCtrl,
    ]) {
      c.clear();
    }
    setState(() {
      _selectedLocation = null;
      loading = false;
      isLogin = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created — please sign in')),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => const _LocationPickerSheet(),
    );
    if (result != null && mounted) {
      setState(() => _selectedLocation = result);
    }
  }

  String get _locationDisplay {
    if (_selectedLocation == null) return '';
    return [
      _selectedLocation!['barangay'],
      _selectedLocation!['city'],
      _selectedLocation!['province'],
      _selectedLocation!['region'],
    ].where((s) => s != null && s.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 0,
                vertical: 48,
              ),
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
                  'PREMIUM MINIMALIST FASHION',
                  style: TextStyle(
                    fontSize: 8,
                    color: Color(0xFF999999),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _tab('LOGIN', isLogin, () => toggle(true)),
                          const SizedBox(width: 32),
                          _tab('SIGN UP', !isLogin, () => toggle(false)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(height: 1, color: const Color(0xFFEEEEEE)),
                      const SizedBox(height: 32),
                      if (isLogin) ..._loginFields() else ..._signupFields(),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading ? null : (isLogin ? login : signup),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            disabledBackgroundColor: const Color(0xFF888888),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            loading
                                ? 'PLEASE WAIT...'
                                : (isLogin ? 'SIGN IN' : 'CREATE ACCOUNT'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
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
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: active ? const Color(0xFF0A0A0A) : const Color(0xFFBBBBBB),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 1.5,
              width: active ? 32 : 0,
              color: const Color(0xFF0A0A0A),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _loginFields() => [
        _field('Email address', emailCtrl),
        const SizedBox(height: 20),
        _field(
          'Password',
          passCtrl,
          obscure: _obscureLogin,
          onToggleObscure: () => setState(() => _obscureLogin = !_obscureLogin),
        ),
      ];

  List<Widget> _signupFields() => [
        Row(
          children: [
            Expanded(child: _field('First name', firstCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _field('Last name', lastCtrl)),
          ],
        ),
        const SizedBox(height: 20),
        _field('Email address', signupEmailCtrl),
        const SizedBox(height: 20),
        _field('Phone number', phoneCtrl),
        const SizedBox(height: 20),
        _field(
          'Password',
          signupPassCtrl,
          obscure: _obscureSignupPass,
          onToggleObscure: () =>
              setState(() => _obscureSignupPass = !_obscureSignupPass),
        ),
        const SizedBox(height: 20),
        _field(
          'Confirm password',
          confirmPassCtrl,
          obscure: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
        ),

        // ── Delivery Address ──────────────────────────────────────
        const SizedBox(height: 32),
        Container(height: 1, color: const Color(0xFFEEEEEE)),
        const SizedBox(height: 28),
        const Text(
          'DELIVERY ADDRESS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A0A0A),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Optional — used for faster checkout',
          style: TextStyle(
            fontSize: 9,
            color: Color(0xFFAAAAAA),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _field('House / Unit no.', houseNumberCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _field('Street name', streetNameCtrl)),
          ],
        ),
        const SizedBox(height: 20),
        _locationField(),
      ];

  Widget _locationField() {
    final hasLocation = _locationDisplay.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOCATION',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasLocation
                        ? _locationDisplay
                        : 'Select barangay, city, province',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasLocation
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFFBBBBBB),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  hasLocation
                      ? Icons.check_circle_outline
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: hasLocation
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFFAAAAAA),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
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
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 8),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
            ),
            suffixIcon: onToggleObscure != null
                ? GestureDetector(
                    onTap: onToggleObscure,
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
            suffixIconConstraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  List<dynamic> regions = [];
  List<dynamic> provinces = [];
  List<dynamic> cities = [];
  List<dynamic> barangays = [];

  String? regionCode, regionName;
  String? provinceCode, provinceName;
  String? cityCode, cityName;
  String? barangayCode, barangayName;

  bool loadingRegions = true;
  bool loadingProvinces = false;
  bool loadingCities = false;
  bool loadingBarangays = false;

  @override
  void initState() {
    super.initState();
    _load('https://psgc.gitlab.io/api/regions/', (data) {
      regions = data;
      loadingRegions = false;
    });
  }

  Future<void> _load(String url, void Function(List<dynamic>) onSuccess) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body) as List;
        data.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        setState(() => onSuccess(data));
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  void _onRegionChanged(String code, String name) {
    setState(() {
      regionCode = code;
      regionName = name;
      provinceCode = provinceName = null;
      cityCode = cityName = null;
      barangayCode = barangayName = null;
      provinces = cities = barangays = [];
      loadingProvinces = true;
    });
    _load('https://psgc.gitlab.io/api/regions/$code/provinces/', (data) {
      provinces = data;
      loadingProvinces = false;
    });
  }

  void _onProvinceChanged(String code, String name) {
    setState(() {
      provinceCode = code;
      provinceName = name;
      cityCode = cityName = null;
      barangayCode = barangayName = null;
      cities = barangays = [];
      loadingCities = true;
    });
    _load(
      'https://psgc.gitlab.io/api/provinces/$code/cities-municipalities/',
      (data) {
        cities = data;
        loadingCities = false;
      },
    );
  }

  void _onCityChanged(String code, String name) {
    setState(() {
      cityCode = code;
      cityName = name;
      barangayCode = barangayName = null;
      barangays = [];
      loadingBarangays = true;
    });
    _load(
      'https://psgc.gitlab.io/api/cities-municipalities/$code/barangays/',
      (data) {
        barangays = data;
        loadingBarangays = false;
      },
    );
  }

  bool get _canConfirm =>
      regionCode != null &&
      provinceCode != null &&
      cityCode != null &&
      barangayCode != null;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 4),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SELECT LOCATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF888888)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dropdown(
                    label: 'REGION',
                    loading: loadingRegions,
                    items: regions,
                    value: regionCode,
                    hint: 'Select region',
                    enabled: true,
                    onChanged: _onRegionChanged,
                  ),
                  const SizedBox(height: 24),
                  _dropdown(
                    label: 'PROVINCE',
                    loading: loadingProvinces,
                    items: provinces,
                    value: provinceCode,
                    hint: regionCode == null ? 'Select region first' : 'Select province',
                    enabled: regionCode != null && !loadingProvinces,
                    onChanged: _onProvinceChanged,
                  ),
                  const SizedBox(height: 24),
                  _dropdown(
                    label: 'CITY / MUNICIPALITY',
                    loading: loadingCities,
                    items: cities,
                    value: cityCode,
                    hint: provinceCode == null ? 'Select province first' : 'Select city',
                    enabled: provinceCode != null && !loadingCities,
                    onChanged: _onCityChanged,
                  ),
                  const SizedBox(height: 24),
                  _dropdown(
                    label: 'BARANGAY',
                    loading: loadingBarangays,
                    items: barangays,
                    value: barangayCode,
                    hint: cityCode == null ? 'Select city first' : 'Select barangay',
                    enabled: cityCode != null && !loadingBarangays,
                    onChanged: (code, name) =>
                        setState(() { barangayCode = code; barangayName = name; }),
                  ),
                  if (_canConfirm) ...[
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFFF6F6F6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELECTED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$barangayName, $cityName,\n$provinceName, $regionName',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0A0A0A),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _canConfirm
                          ? () => Navigator.of(context).pop({
                                'region': regionName ?? '',
                                'province': provinceName ?? '',
                                'city': cityName ?? '',
                                'barangay': barangayName ?? '',
                                'regionCode': regionCode ?? '',
                                'provinceCode': provinceCode ?? '',
                                'cityCode': cityCode ?? '',
                                'barangayCode': barangayCode ?? '',
                              })
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A0A0A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFFCCCCCC),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'CONFIRM LOCATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
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

  Widget _dropdown({
    required String label,
    required bool loading,
    required List<dynamic> items,
    required String? value,
    required String hint,
    required bool enabled,
    required void Function(String code, String name) onChanged,
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
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1),
            ),
          ),
          padding: const EdgeInsets.only(bottom: 2),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                )
              : DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: enabled
                        ? const Color(0xFF888888)
                        : const Color(0xFFCCCCCC),
                  ),
                  hint: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled
                          ? const Color(0xFFBBBBBB)
                          : const Color(0xFFDDDDDD),
                    ),
                  ),
                  disabledHint: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFDDDDDD),
                    ),
                  ),
                  items: enabled
                      ? items
                          .map<DropdownMenuItem<String>>(
                            (item) => DropdownMenuItem<String>(
                              value: item['code'] as String,
                              child: Text(
                                item['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0A0A0A),
                                ),
                              ),
                            ),
                          )
                          .toList()
                      : null,
                  onChanged: enabled
                      ? (code) {
                          if (code == null) return;
                          final item =
                              items.firstWhere((i) => i['code'] == code);
                          onChanged(code, item['name'] as String);
                        }
                      : null,
                ),
        ),
      ],
    );
  }
}
