import 'package:haptic_feedback/haptic_feedback.dart';

class HapticService {
  static bool enabled = true;

  static Future<void> lightImpact() async {
    if (!enabled) return;
    await Haptics.vibrate(HapticsType.light);
  }

  static Future<void> mediumImpact() async {
    if (!enabled) return;
    await Haptics.vibrate(HapticsType.medium);
  }

  static Future<void> heavyImpact() async {
    if (!enabled) return;
    await Haptics.vibrate(HapticsType.heavy);
  }

  static Future<void> success() async {
    if (!enabled) return;
    await Haptics.vibrate(HapticsType.success);
  }

  static Future<void> warning() async {
    if (!enabled) return;
    await Haptics.vibrate(HapticsType.warning);
  }

  static Future<void> error() async {
    if (!enabled) return;
    await Haptics.vibrate(HapticsType.error);
  }

  static Future<void> selectionClick() async {
    if (!enabled) return;
    await Haptics.vibrate(HapticsType.selection);
  }
}
