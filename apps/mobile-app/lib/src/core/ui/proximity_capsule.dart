import 'package:flutter/material.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass.dart';

class ProximityCapsule extends StatelessWidget {
  final double fillPercentage; // 0.0 to 1.0

  const ProximityCapsule({super.key, required this.fillPercentage});

  @override
  Widget build(BuildContext context) {
    return GlassPanel.pill(
      width: 150,
      height: 40,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Background Track
          Container(color: Colors.white.withOpacity(0.05)),
          
          // Fill Bar (Animated)
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: 500.ms,
                width: constraints.maxWidth * fillPercentage.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: DesignTokens.proximityGradient,
                ),
              );
            },
          ),
          
          // Hatching Pattern (Simulated with text/icon for now, or CustomPainter)
          Center(
            child: Text(
              "PROXIMITY",
              style: TextStyle(
                fontSize: 10, 
                letterSpacing: 2, 
                color: Colors.white.withOpacity(0.5)
              ),
            ),
          ),
        ],
      ),
    );
  }
}
