import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Asks for the notification permission used by download notifications and by
/// the download foreground service (Android 13+).
///
/// Best effort: downloads keep working when the permission is denied.
Future<bool> ensureNotificationPermission() async {
  try {
    if (await Permission.notification.isGranted) return true;
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  } catch (error) {
    debugPrint('Notification permission unavailable: $error');
    return false;
  }
}
