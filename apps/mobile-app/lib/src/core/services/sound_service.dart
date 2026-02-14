import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool enabled = true;

  static Future<void> play(String assetName) async {
    if (!enabled) return;
    await _player.play(AssetSource('sounds/$assetName'));
  }

  static Future<void> click() => play('ui_click.mp3');
  static Future<void> success() => play('ui_success.mp3');
  static Future<void> notification() => play('ui_notification.mp3');
  static Future<void> scan() => play('ui_scan.mp3');
}
