import 'package:flutter/services.dart';

/// Thin Dart wrapper for the `tiebanana/player_utils` MethodChannel
/// implemented in `android/app/src/main/kotlin/pers/aobanana/Tiebanana/
/// MainActivity.kt`. Only used by the video player gestures; no-ops on
/// other platforms.
class PlayerSystemUtils {
  PlayerSystemUtils._();

  static const MethodChannel _channel = MethodChannel('tiebanana/player_utils');

  /// System media volume, normalized to 0..1. Returns 0.5 on platforms
  /// without the platform channel.
  static Future<double> getSystemVolume() async {
    try {
      return await _channel.invokeMethod<double>('getSystemVolume') ?? 0.5;
    } on MissingPluginException {
      return 0.5;
    }
  }

  static Future<void> setSystemVolume(double value) async {
    try {
      await _channel
          .invokeMethod('setSystemVolume', {'value': value.clamp(0.0, 1.0)});
    } on MissingPluginException {
      // Ignore.
    }
  }

  /// Screen brightness 0..1; -1.0 means "follow the system setting".
  /// Returns 0.5 on platforms without the platform channel.
  static Future<double> getBrightness() async {
    try {
      return await _channel.invokeMethod<double>('getBrightness') ?? 0.5;
    } on MissingPluginException {
      return 0.5;
    }
  }

  static Future<void> setBrightness(double value) async {
    try {
      await _channel
          .invokeMethod('setBrightness', {'value': value.clamp(0.0, 1.0)});
    } on MissingPluginException {
      // Ignore.
    }
  }
}
