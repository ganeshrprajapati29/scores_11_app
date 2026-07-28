import 'package:flutter/services.dart';

class NotificationEffectService {
  NotificationEffectService._();

  static Future<void> play({String sound = 'scores11'}) async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.mediumImpact();
    } catch (_) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }
}
