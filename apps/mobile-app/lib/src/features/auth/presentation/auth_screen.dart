import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import '../../../core/widgets/liquid_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0: Landing, 1: Login, 2: SignUp-Creds, 3: SignUp-Identity, 4: SignUp-Persona
  bool _isLoading = false;

  // Form Controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  
  DateTime? _selectedBirthdate;
  String _selectedGender = 'Not Specified';
  String _selectedPersonality = 'Explorer';

  final List<String> _genders = ['Male', 'Female', 'Non-Binary', 'Other', 'Not Specified'];
  final List<String> _personalities = [
    'Explorer', 'Visionary', 'Guardian', 'Rebel', 'Architect', 'Mystic'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _nextPage(int page) {
    setState(() => _currentStep = page);
    _pageController.animateToPage(
      page,
      duration: 600.ms,
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showError("Please enter email and password");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOAuth(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        emailRedirectTo: 'io.supabase.traces://login-callback/',
        data: {
          'username': _usernameCtrl.text.trim(),
          'full_name': _nameCtrl.text.trim(),
          'birthdate': _selectedBirthdate?.toIso8601String(),
          'gender': _selectedGender,
          'bio': _bioCtrl.text.trim(),
          'personality_type': _selectedPersonality,
          'avatar_url': 'https://api.dicebear.com/7.x/bottts/svg?seed=${_usernameCtrl.text.trim()}',
        },
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.signalRed.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DesignTokens.liquidBlue,
              onPrimary: Colors.white,
              surface: DesignTokens.glassDarkBase,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const LiquidBackground(),
            
            // Floating Ambient Particles
            Positioned(
              top: 100, right: -50,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.liquidBlue.withOpacity(0.1),
                  boxShadow: [BoxShadow(color: DesignTokens.liquidBlue.withOpacity(0.2), blurRadius: 50)],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .moveY(begin: 0, end: 30, duration: 4.seconds)
               .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 5.seconds),
            ),
            Positioned(
              bottom: 200, left: -30,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.electricPurple.withOpacity(0.1),
                  boxShadow: [BoxShadow(color: DesignTokens.electricPurple.withOpacity(0.2), blurRadius: 40)],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .moveY(begin: 0, end: -40, duration: 6.seconds)
               .scale(begin: const Offset(1,1), end: const Offset(0.8, 0.8), duration: 7.seconds),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "TRACES",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white.withOpacity(0.95),
                      shadows: [
                        Shadow(color: Colors.cyan.withOpacity(0.6), blurRadius: 30),
                      ],
                    ),
                  ).animate().fadeIn().moveY(begin: -20, end: 0),
                  
                  Text(
                    "LEAVE YOUR MARK ON REALITY",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildLandingStep(),
                        _buildLoginStep(),
                        _buildSignUpCredentialsStep(),
                        _buildSignUpIdentityStep(),
                        _buildSignUpPersonaStep(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: GlassPanel(
                    width: 100, height: 100, blur: 20,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _glassButton("LOGIN", () => _nextPage(1)),
          const SizedBox(height: 20),
          _glassButton("CREATE ACCOUNT", () => _nextPage(2), isPrimary: true),
          const SizedBox(height: 40),
          _buildOAuthRow(),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildLoginStep() {
    return _buildFormContainer(
      title: "LOGIN",
      children: [
        _glassTextField("EMAIL", _emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _glassTextField("PASSWORD", _passCtrl, isPassword: true, icon: Icons.lock_outline),
        const SizedBox(height: 32),
        _glassButton("ACCESS", _handleLogin, isPrimary: true),
        const SizedBox(height: 24),
        _buildOAuthRow(),
        TextButton(
          onPressed: () => _nextPage(0),
          child: Text("CANCEL", style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ),
      ],
    );
  }

  Widget _buildSignUpCredentialsStep() {
    return _buildFormContainer(
      title: "CREATE ACCOUNT",
      children: [
        _glassTextField("EMAIL", _emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _glassTextField("PASSWORD", _passCtrl, isPassword: true, icon: Icons.lock_outline),
        const SizedBox(height: 16),
        _glassTextField("CONFIRM PASSWORD", _confirmPassCtrl, isPassword: true, icon: Icons.lock_reset),
        const SizedBox(height: 32),
        _glassButton("NEXT", () {
          if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _confirmPassCtrl.text.isEmpty) {
            _showError("All fields are required");
            return;
          }
          if (_passCtrl.text != _confirmPassCtrl.text) {
            _showError("Passwords do not match");
            return;
          }
          if (_passCtrl.text.length < 6) {
            _showError("Password must be at least 6 characters");
            return;
          }
          FocusManager.instance.primaryFocus?.unfocus();
          _nextPage(3);
        }, isPrimary: true),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => _nextPage(0),
          child: Text("ABORT", style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ),
      ],
    );
  }

  Widget _buildOAuthRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("OR CONNECT WITH", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 1.5)),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _oAuthButton(FontAwesomeIcons.google, () => _handleOAuth(OAuthProvider.google)),
            const SizedBox(width: 20),
            _oAuthButton(FontAwesomeIcons.apple, () => _handleOAuth(OAuthProvider.apple)),
            const SizedBox(width: 20),
            _oAuthButton(FontAwesomeIcons.discord, () => _handleOAuth(OAuthProvider.discord)),
          ],
        ),
      ],
    );
  }

  Widget _oAuthButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        width: 60, height: 60, padding: EdgeInsets.zero, radius: 20,
        backgroundColor: Colors.white.withOpacity(0.05),
        child: Center(child: FaIcon(icon, color: Colors.white, size: 24)),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeInOut);
  }

  Widget _buildSignUpIdentityStep() {
    return _buildFormContainer(
      title: "PROFILE DETAILS",
      children: [
        // Profile Picture Placeholder
        Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // In future: pick image from gallery
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: DesignTokens.liquidBlue.withOpacity(0.5), width: 2),
                  ),
                  child: Icon(Icons.person, size: 40, color: Colors.white.withOpacity(0.5)),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: DesignTokens.liquidBlue),
                  child: const Icon(Icons.add_a_photo, size: 14, color: Colors.white),
                ),
              ],
            ),
          ).animate().scale(delay: 200.ms),
        ),
        const SizedBox(height: 24),
        _glassTextField("USERNAME", _usernameCtrl, icon: Icons.alternate_email),
        const SizedBox(height: 16),
        _glassTextField("FULL NAME", _nameCtrl, icon: Icons.person_outline, textCapitalization: TextCapitalization.words),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: _glassTextField(
              "BIRTHDATE", 
              TextEditingController(text: _selectedBirthdate?.toLocal().toString().split(' ')[0] ?? ''), 
              icon: Icons.calendar_today
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Gender Dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("GENDER", style: TextStyle(color: DesignTokens.liquidBlue.withOpacity(0.9), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGender,
                  dropdownColor: DesignTokens.glassDarkBase,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: _genders.map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedGender = newValue!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => _nextPage(2),
              child: Text("BACK", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            _glassButton("NEXT", () {
              if (_usernameCtrl.text.isEmpty || _selectedBirthdate == null) {
                _showError("Identity and birthdate required");
                return;
              }
              FocusManager.instance.primaryFocus?.unfocus();
              _nextPage(4);
            }, isPrimary: true, width: 120),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpPersonaStep() {
    return _buildFormContainer(
      title: "ABOUT YOU",
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("BIO", style: TextStyle(color: DesignTokens.liquidBlue.withOpacity(0.9), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.2),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _bioCtrl,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "YOUR MANIFESTO...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ARCHETYPE", style: TextStyle(color: DesignTokens.liquidBlue.withOpacity(0.9), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.2),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPersonality,
                  dropdownColor: DesignTokens.glassDarkBase,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: _personalities.map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedPersonality = newValue!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => _nextPage(3),
              child: Text("BACK", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            _glassButton("INITIALIZE", _handleSignUp, isPrimary: true, width: 140),
          ],
        ),
      ],
    );
  }

  Widget _buildFormContainer({required String title, required List<Widget> children}) {
    return Center(
      child: GlassPanel(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.all(28),
        blur: 30,
        backgroundColor: Colors.white.withOpacity(0.08),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ...children,
            ],
          ),
        ),
      ),
    ).animate(key: ValueKey(_currentStep)).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _glassTextField(String label, TextEditingController controller, {bool isPassword = false, IconData? icon, TextInputType? keyboardType, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(color: DesignTokens.liquidBlue.withOpacity(0.9), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, color: Colors.white.withOpacity(0.5), size: 18) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassButton(String text, VoidCallback onPressed, {bool isPrimary = false, double? width}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary 
            ? LinearGradient(colors: [DesignTokens.liquidBlue.withOpacity(0.8), const Color(0xFF0072FF).withOpacity(0.8)])
            : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isPrimary ? DesignTokens.liquidBlue.withOpacity(0.5) : Colors.white.withOpacity(0.2)),
          boxShadow: isPrimary ? [BoxShadow(color: DesignTokens.liquidBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))] : [],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

