import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'glass.dart';

/// A specialized glass button that provides haptic and visual feedback.
class AnimatedGlassButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onTap;
  final double size;
  final bool isCircle;

  const AnimatedGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 50.0,
    this.isCircle = true,
  });

  @override
  State<AnimatedGlassButton> createState() => _AnimatedGlassButtonState();
}

class _AnimatedGlassButtonState extends State<AnimatedGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticService.mediumImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticService.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: 100.ms,
        child: GlassPanel(
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.zero,
          radius: widget.isCircle ? DesignTokens.radiusFull : DesignTokens.radiusMedium,
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}
