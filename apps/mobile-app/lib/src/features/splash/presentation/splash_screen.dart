import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/widgets/liquid_orb.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'package:traces_mobile/src/core/services/sound_service.dart';
import '../../profile/data/user_repository.dart';
import '../../../core/widgets/liquid_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with WidgetsBindingObserver {
  final int _minSplashTime = 6000; // 6 Seconds Minimum
  bool _isCheckingLocation = false;
  String _statusMessage = "LOADING REALITY...";
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleInitialization();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCheckingLocation) {
      _checkLocationRequirements();
    }
  }

  Future<void> _handleInitialization() async {
    final stopwatch = Stopwatch()..start();
    
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < _minSplashTime) {
      await Future.delayed(Duration(milliseconds: _minSplashTime - elapsed));
    }

    await _checkLocationRequirements();
  }

  Future<void> _checkLocationRequirements() async {
    if (!mounted) return;
    setState(() {
      _isCheckingLocation = true;
      _statusMessage = "CALIBRATING SENSORS...";
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showLocationDialog("GPS REQUIRED", "Location services must be enabled to explore reality.", true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showLocationDialog("PERMISSION DENIED", "Location access is required to find Traces.", false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showLocationDialog("PERMISSION BLOCKED", "Please enable location in system settings to proceed.", true);
      return;
    }

    if (mounted) {
      setState(() => _isCheckingLocation = false);
      _checkAuthAndNavigate();
    }
  }

  void _showLocationDialog(String title, String message, bool openSettings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: GlassPanel(
            radius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off, size: 48, color: DesignTokens.signalRed),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (openSettings) {
                      Geolocator.openLocationSettings();
                    } else {
                      _checkLocationRequirements();
                    }
                  },
                  child: const Text("ENABLE"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    setState(() => _statusMessage = "SYNCING IDENTITY...");
    
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    if (mounted) {
      if (isLoggedIn) {
        try {
          // Fetch Profile
          final profileData = await Supabase.instance.client.from('profiles').select('birthdate, personality_type').eq('id', session.user.id).single();
          
          // Fetch Settings
          final settingsData = await ref.read(userRepositoryProvider).getSettings();

          // Apply settings
          HapticService.enabled = settingsData['haptic_enabled'] ?? true;
          SoundService.enabled = settingsData['sound_effects'] ?? true;
          
          if (mounted) {
            if (profileData['birthdate'] == null || profileData['personality_type'] == null) {
              context.go('/complete-profile');
            } else {
              context.go('/home');
            }
          }
        } catch (e) {
          if (mounted) context.go('/home');
        }
      } else {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LiquidBackground(),
          
          Center(
            child: const LiquidOrb(size: 350)
                .animate()
                .fadeIn(duration: 1000.ms)
                .scale(duration: 1500.ms, curve: Curves.elasticOut),
          ),

          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: GlassPanel.pill(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                blur: 20,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
        ],
      ),
    );
  }
}
