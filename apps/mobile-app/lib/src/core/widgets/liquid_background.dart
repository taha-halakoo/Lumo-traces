import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';

class LiquidBackground extends StatefulWidget {
  const LiquidBackground({super.key});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  double _targetX = 0.0;
  double _targetY = 0.0;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    // Used gyroscopeEventStream() instead of deprecated gyroscopeEvents
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      // Integrate gyro data for position
      // Inverted Y because tilting down (positive Y gyro) should move background up (negative Y offset)
      _targetX += event.y * 8.0; 
      _targetY += event.x * 8.0; 
      
      // Clamp to prevent drifting too far
      _targetX = _targetX.clamp(-80.0, 80.0);
      _targetY = _targetY.clamp(-80.0, 80.0);
      
      if (mounted) {
        setState(() {
          // Smooth interpolation
          _xOffset += (_targetX - _xOffset) * 0.05;
          _yOffset += (_targetY - _yOffset) * 0.05;
        });
      }
    });
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.glassDarkBase,
      ),
      child: Stack(
        children: [
          // Deep Blue Orb (Far Layer - Moves Slower)
          Positioned(
            top: -100,
            left: -100,
            child: Transform.translate(
              offset: Offset(_xOffset * 0.5, _yOffset * 0.5),
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DesignTokens.liquidBlue.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(duration: 7.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
               .move(duration: 8.seconds, begin: const Offset(0, 0), end: const Offset(30, 30)),
            ),
          ),
          
          // Purple/Pink Orb (Near Layer - Moves Faster)
          Positioned(
            bottom: -100,
            right: -100,
            child: Transform.translate(
              offset: Offset(_xOffset * 1.2, _yOffset * 1.2),
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DesignTokens.electricPurple.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(duration: 6.seconds, begin: const Offset(1, 1), end: const Offset(1.3, 1.3))
               .move(duration: 7.seconds, begin: const Offset(0, 0), end: const Offset(-50, -50)),
            ),
          ),
          
          // Neon Green Highlight (Mid Layer - Opposite movement)
          Positioned(
            top: 200,
            right: -50,
            child: Transform.translate(
              offset: Offset(-_xOffset * 0.8, -_yOffset * 0.8),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DesignTokens.neonGreen.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(duration: 9.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1)),
            ),
          ),
        ],
      ),
    );
  }
}
