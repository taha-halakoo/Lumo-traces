import 'package:flutter/services.dart';

class HapticService {
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> success() async {
    await HapticFeedback.vibrate(); // Fallback/Standard
    // On iOS we could do more specific patterns
  }

  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
  
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
