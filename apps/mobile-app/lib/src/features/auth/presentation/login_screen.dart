import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await authRepo.signIn(email, password);
      } else {
        await authRepo.signUp(email, password);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please verify email or log in.')),
          );
        }
      }
      
      if (mounted) {
        context.go('/map');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // 1. Deep Ocean Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [DesignTokens.glassDarkBase, Color(0xFF0F172A)],
              ),
            ),
          ),
          
          // 2. Liquid Blobs (Animated Background)
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.2, duration: 4.seconds, curve: Curves.easeInOut)
             .move(begin: const Offset(0, 0), end: const Offset(20, 20), duration: 5.seconds),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.3, duration: 6.seconds, curve: Curves.easeInOut)
             .move(begin: const Offset(0, 0), end: const Offset(-20, -20), duration: 7.seconds),
          ),

          // 3. Glass Panel Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassPanel(
                padding: const EdgeInsets.all(32),
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo / Title
                    Icon(Icons.waves, size: 64, color: theme.colorScheme.primary)
                        .animate().fadeIn(duration: 800.ms).slideY(begin: -0.5),
                    const SizedBox(height: 16),
                    Text(
                      "TRACES",
                      style: theme.textTheme.displayMedium?.copyWith(letterSpacing: 4),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                      "The world is liquid glass.",
                      style: theme.textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 48),

                    // Inputs
                    _buildGlassInput(context, "Email", Icons.email_outlined, _emailController),
                    const SizedBox(height: 16),
                    _buildGlassInput(context, "Password", Icons.lock_outline, _passwordController, obscureText: true),
                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isLogin ? "ENTER THE FLOW" : "JOIN THE NETWORK"),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
                    
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? "Need an account? Sign Up" : "Already have an account? Log In",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput(BuildContext context, String hint, IconData icon, TextEditingController controller, {bool obscureText = false}) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: 12,
      backgroundColor: Colors.white.withOpacity(0.05),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
