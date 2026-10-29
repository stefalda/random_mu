import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:random_mu/services/download_models.dart';

/// Shows user-facing notifications about offline downloads.
///
/// Deliberately optional: when the plugin, the platform channel or the
/// notification permission is unavailable, downloads keep working silently.
class NotificationService {
  static const String channelId = 'random_mu_downloads';
  static const String channelName = 'Downloads';
  static const String channelDescription =
      'Offline download progress and results';

  /// Completions arriving inside this window collapse into one summary.
  final Duration batchWindow;

  /// Test seam: replaces the platform call.
  final Future<void> Function(String title, String? body)? showOverride;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final List<DownloadItem> _pendingCompletions = [];
  Timer? _batchTimer;
  bool _ready = false;
  int _nextId = 0;

  NotificationService({
    this.batchWindow = const Duration(seconds: 3),
    this.showOverride,
  });

  bool get isReady => _ready;

  /// Initialises the plugin, its channel and the Android 13+ permission.
  Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      );
      await _plugin.initialize(settings: settings);
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.low,
        ),
      );
      await android?.requestNotificationsPermission();
      _ready = true;
    } catch (error) {
      debugPrint('Download notifications unavailable: $error');
      _ready = false;
    }
  }

  /// Queues a completion notification (batched with its neighbours).
  void downloadCompleted(DownloadItem item) {
    _pendingCompletions.add(item);
    _batchTimer?.cancel();
    _batchTimer = Timer(batchWindow, () => unawaited(flushCompletions()));
  }

  /// Reports a failed download immediately.
  Future<void> downloadFailed(DownloadItem item) {
    return _show(failureMessage(item), item.errorMessage);
  }

  /// Emits the pending completion notification(s) right away.
  @visibleForTesting
  Future<void> flushCompletions() async {
    _batchTimer?.cancel();
    _batchTimer = null;
    final items = List<DownloadItem>.of(_pendingCompletions);
    _pendingCompletions.clear();
    if (items.isEmpty) return;

    if (items.length == 1) {
      await _show(completionMessage(items.single), batchBody(items));
    } else {
      await _show(batchMessage(items.length), batchBody(items));
    }
  }

  Future<void> _show(String title, String? body) async {
    final override = showOverride;
    if (override != null) {
      await override(title, body);
      return;
    }
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Cannot show download notification: $error');
    }
  }

  // --- Message formatting (pure, unit tested) ---

  static String typeLabel(DownloadItemType type) {
    switch (type) {
      case DownloadItemType.playlist:
        return 'Playlist';
      case DownloadItemType.album:
        return 'Album';
      case DownloadItemType.artist:
        return 'Artist';
      case DownloadItemType.favorites:
        return 'Favorites';
    }
  }

  static String completionMessage(DownloadItem item) {
    if (item.type == DownloadItemType.favorites) return 'Favorites downloaded';
    return "${typeLabel(item.type)} '${item.title}' downloaded";
  }

  static String batchMessage(int count) {
    if (count == 1) return '1 download completed';
    return '$count downloads completed';
  }

  static String failureMessage(DownloadItem item) {
    if (item.type == DownloadItemType.favorites) {
      return 'Favorites download failed';
    }
    return "${typeLabel(item.type)} '${item.title}' download failed";
  }

  static String batchBody(List<DownloadItem> items) {
    return items.map((item) => item.title).join(', ');
  }
}
