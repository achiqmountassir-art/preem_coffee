import 'admin_notification_sound_stub.dart'
    if (dart.library.html) 'admin_notification_sound_web.dart' as impl;

/// Plays a short alert when a new pending order arrives (web-capable).
void playAdminOrderNotificationSound() => impl.playAdminOrderNotificationSound();
