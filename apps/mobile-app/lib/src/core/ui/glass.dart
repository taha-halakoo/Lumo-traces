import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blur;
  final Color backgroundColor;
  final Border? border;
  final Gradient? gradient;

  const GlassPanel({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.radius = 24, // Rounded corners
    this.blur = 30, // High blur by default (20-40px requested)
    this.backgroundColor = DesignTokens.glassDarkBase,
    this.border,
    this.gradient,
  });

  const GlassPanel.pill({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.radius = 100,
    this.blur = 30,
    this.backgroundColor = DesignTokens.glassDarkBase,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(radius),
              border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
