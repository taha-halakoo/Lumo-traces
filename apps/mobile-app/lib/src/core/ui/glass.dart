import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';

/// The core component of the Liquid Glass system.
/// Implements the "IOS Liquid Glass" aesthetic:
/// - Heavy Blur (BackdropFilter)
/// - Subtle Gradient Fill (White opacity)
/// - "Light Catching" Border
/// - Soft Shadow
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;
  final BoxShape shape;

  const GlassPanel({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = DesignTokens.radiusMedium,
    this.blur = DesignTokens.blurMedium,
    this.backgroundColor,
    this.border,
    this.onTap,
    this.shape = BoxShape.rectangle,
  });

  /// Factory for a "Pill" shape (Search bar, Scanning button)
  factory GlassPanel.pill({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    Color? backgroundColor,
    Border? border,
    double blur = DesignTokens.blurMedium,
  }) {
    return GlassPanel(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      radius: DesignTokens.radiusFull,
      blur: blur,
      backgroundColor: backgroundColor,
      border: border,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: DesignTokens.shadowFloating,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: shape == BoxShape.circle ? BorderRadius.circular(1000) : BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: DesignTokens.liquidGradient,
              shape: shape,
              borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
              border: border ?? Border.all(
                color: Colors.white.withOpacity(DesignTokens.opacityBorder),
                width: 1.0,
              ),
              color: backgroundColor,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticService.lightImpact();
          onTap!();
        },
        behavior: HitTestBehavior.translucent,
        child: panel,
      );
    }
    return panel;
  }
}
