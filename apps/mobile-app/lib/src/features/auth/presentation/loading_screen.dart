import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

enum LoadingState { initial, loading, loaded, authenticated, unauthenticated }

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  late Flutter3DController _controller;
  LoadingState _state = LoadingState.initial;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _state = LoadingState.loading);

    // Minimum wait time of 1.5 seconds to show the animation
    final minWait = Future.delayed(const Duration(milliseconds: 1500));
    
    // Check Auth Status
    final session = Supabase.instance.client.auth.currentSession;
    
    // Simulate loading resources (or real initialization)
    // Here we can preload images, initialize services, etc.
    await Future.delayed(const Duration(milliseconds: 500)); 
    setState(() => _progress = 0.3);
    
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _progress = 0.6);

    await minWait;
    setState(() => _progress = 1.0);

    if (session != null) {
      setState(() => _state = LoadingState.authenticated);
      if (mounted) context.go('/home'); // Adjust route as needed
    } else {
      setState(() => _state = LoadingState.unauthenticated);
      if (mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Deep space black for contrast
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1a1a2e), // Deep Blue/Purple
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // 3D Liquid Sphere
          Center(
            child: SizedBox(
              height: 400,
              width: 400,
              child: Flutter3DViewer(
                src: 'assets/models/liquid_glass_sphere.glb',
                controller: _controller,
                progressBarColor: Colors.transparent, // Hide default loader
                onLoad: (modelAddress) {
                  _controller.playAnimation();
                  _controller.setCameraOrbit(20, 20, 5);
                },
                onError: (error) {
                  debugPrint('3D Model Error: $error');
                  // Fallback if model fails
                },
              )
              .animate()
              .fadeIn(duration: 800.ms, curve: Curves.easeOut)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.easeOut)
              .then()
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 5000.ms, curve: Curves.linear), // Idle rotation
            ),
          ),

          // Glass Overlay / Loading Indicator
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(
                    'TRACES',
                    style: TextStyle(
                      fontFamily: 'Orbitron', // Assuming font exists or fallback
                      fontSize: 24,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 500.ms).shimmer(duration: 2000.ms),
                  const SizedBox(height: 20),
                  // Custom Progress Bar (Liquid Style)
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Colors.cyanAccent, Colors.purpleAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
