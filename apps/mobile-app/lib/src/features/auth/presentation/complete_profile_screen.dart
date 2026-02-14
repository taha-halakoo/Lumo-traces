import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import '../../../core/widgets/liquid_background.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  
  DateTime? _selectedBirthdate;
  String _selectedPersonality = 'Explorer';

  final List<String> _personalities = [
    'Explorer', 'Visionary', 'Guardian', 'Rebel', 'Architect', 'Mystic'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Pre-fill existing data if available (e.g. from OAuth metadata)
      final data = await Supabase.instance.client.from('profiles').select().eq('id', user.id).single();
      if (mounted) {
        setState(() {
          _usernameCtrl.text = data['username'] ?? '';
          if (_usernameCtrl.text.startsWith('user_')) {
             _usernameCtrl.clear(); // Clear if it's a generated default so user sets a real one
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameCtrl.dispose();
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

  Future<void> _completeProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw "User not authenticated";

      await Supabase.instance.client.from('profiles').update({
        'username': _usernameCtrl.text.trim(),
        'birthdate': _selectedBirthdate?.toIso8601String(),
        'bio': _bioCtrl.text.trim(),
        'personality_type': _selectedPersonality,
      }).eq('id', user.id);

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  "COMPLETE LINK",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ).animate().fadeIn().moveY(begin: -20, end: 0),
                
                Text(
                  "CALIBRATE YOUR IDENTITY",
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 4,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildIdentityStep(),
                      _buildPersonaStep(),
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
                  width: 100,
                  height: 100,
                  blur: 20,
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdentityStep() {
    return _buildFormContainer(
      title: "IDENTITY PARAMS (1/2)",
      children: [
        _glassTextField("USERNAME", _usernameCtrl, icon: Icons.alternate_email),
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
        const SizedBox(height: 32),
        _glassButton("NEXT", () {
          if (_usernameCtrl.text.isNotEmpty && _selectedBirthdate != null) {
            _nextPage(1);
          } else {
            _showError("Identity required");
          }
        }, isPrimary: true),
      ],
    );
  }

  Widget _buildPersonaStep() {
    return _buildFormContainer(
      title: "CORE MATRIX (2/2)",
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
             color: Colors.white.withOpacity(0.05),
             borderRadius: BorderRadius.circular(15),
             border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _bioCtrl,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "BIO / MANIFESTO...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
             color: Colors.white.withOpacity(0.05),
             borderRadius: BorderRadius.circular(15),
             border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPersonality,
              dropdownColor: DesignTokens.glassDarkBase,
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: _personalities.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedPersonality = newValue!);
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => _nextPage(0),
              child: Text("BACK", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            _glassButton("FINALIZE", _completeProfile, isPrimary: true),
          ],
        ),
      ],
    );
  }

  Widget _buildFormContainer({required String title, required List<Widget> children}) {
    return Center(
      child: GlassPanel(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
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
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _glassTextField(String label, TextEditingController controller, {bool isPassword = false, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            color: DesignTokens.liquidBlue.withOpacity(0.9), 
            fontSize: 10, 
            letterSpacing: 2, 
            fontWeight: FontWeight.bold
          )
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

  Widget _glassButton(String text, VoidCallback onPressed, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary 
            ? LinearGradient(colors: [DesignTokens.liquidBlue.withOpacity(0.8), const Color(0xFF0072FF).withOpacity(0.8)])
            : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isPrimary ? DesignTokens.liquidBlue.withOpacity(0.5) : Colors.white.withOpacity(0.2)
          ),
          boxShadow: isPrimary 
            ? [BoxShadow(color: DesignTokens.liquidBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))]
            : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
