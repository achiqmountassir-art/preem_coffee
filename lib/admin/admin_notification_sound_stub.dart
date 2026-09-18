import 'dart:async';

import 'package:flutter/services.dart';

void playAdminOrderNotificationSound() {
  // Soft non-web fallback.
  SystemSound.play(SystemSoundType.click);
  Future<void>.delayed(const Duration(milliseconds: 160), () {
    SystemSound.play(SystemSoundType.click);
  });
}
