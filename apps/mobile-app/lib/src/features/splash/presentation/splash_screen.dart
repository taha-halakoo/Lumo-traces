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
  final int _minSplashTime = 3000; // 3 Seconds for effect
  bool _isCheckingLocation = false;
  String _statusMessage = "INITIALIZING REALITY...";
  double _loadProgress = 0.0;
  
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
    // Simulate loading progress for effect
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _loadProgress += 0.02;
          if (_loadProgress >= 1.0) {
            _loadProgress = 1.0;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });

    final stopwatch = Stopwatch()..start();
    
    // Check services in parallel if possible, but for splash effect we wait a bit
    await Future.delayed(const Duration(milliseconds: 2000));

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
                const Icon(Icons.location_off, size: 48, color: DesignTokens.signalRed),
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
          
          // Central Liquid Orb Effect
          Center(
            child: const LiquidOrb(size: 300)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2000.ms, curve: Curves.easeInOut),
          ),

          // Loading Text & Progress
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GlassPanel.pill(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  blur: 20,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: _loadProgress,
                          valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.liquidBlue),
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
                
                const SizedBox(height: 20),
                
                // Version
                Text(
                  "V 1.0.0 // LIQUID GLASS",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
