import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _enabled = true;

  static void setEnabled(bool val) => _enabled = val;
  static bool get enabled => _enabled;

  static Future<void> playCorrect() async {
    HapticFeedback.lightImpact();
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/correct.mp3'), volume: 0.6);
    } catch (_) {}
  }

  static Future<void> playWrong() async {
    HapticFeedback.heavyImpact();
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/wrong.mp3'), volume: 0.6);
    } catch (_) {}
  }

  static Future<void> playComplete() async {
    HapticFeedback.mediumImpact();
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/complete.mp3'), volume: 0.7);
    } catch (_) {}
  }

  static Future<void> playTap() async {
    HapticFeedback.selectionClick();
  }
}
