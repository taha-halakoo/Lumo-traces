import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class HapticService {
  static bool enabled = true;

  static Future<void> lightImpact() async {
    if (!enabled) return;
    try {
      await Haptics.vibrate(HapticsType.light);
    } catch (_) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> mediumImpact() async {
    if (!enabled) return;
    try {
      await Haptics.vibrate(HapticsType.medium);
    } catch (_) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> heavyImpact() async {
    if (!enabled) return;
    try {
      await Haptics.vibrate(HapticsType.heavy);
    } catch (_) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> success() async {
    if (!enabled) return;
    try {
      await Haptics.vibrate(HapticsType.success);
    } catch (_) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> warning() async {
    if (!enabled) return;
    try {
      await Haptics.vibrate(HapticsType.warning);
    } catch (_) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> error() async {
    if (!enabled) return;
    try {
      await Haptics.vibrate(HapticsType.error);
    } catch (_) {
      await HapticFeedback.vibrate();
    }
  }

  static Future<void> selectionClick() async {
    if (!enabled) return;
    try {
      await Haptics.vibrate(HapticsType.selection);
    } catch (_) {
      await HapticFeedback.selectionClick();
    }
  }
}
