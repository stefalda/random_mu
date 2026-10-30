import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:random_mu/l10n/l10n_static.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/permissions.dart';

/// Shows user-facing notifications about offline downloads.
///
/// Deliberately optional: when the plugin, the platform channel or the
/// notification permission is unavailable, downloads keep working silently.
class NotificationService {
  static const String channelId = 'random_mu_downloads';
  static String get channelName => appL10n.downloadsTitle;
  static String get channelDescription => appL10n.offlineDownloadChannel;

  /// Completions arriving inside this window collapse into one summary.
  final Duration batchWindow;

  /// Test seam: replaces the platform call.
  final Future<void> Function(String title, String? body)? showOverride;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final List<DownloadItem> _pendingCompletions = [];
  Timer? _batchTimer;
  bool _ready = false;
  bool _permissionRequested = false;
  int _nextId = 0;

  NotificationService({
    this.batchWindow = const Duration(seconds: 3),
    this.showOverride,
  });

  bool get isReady => _ready;

  /// Initialises the plugin and its channel. Never asks for a permission here:
  /// the Android 13+ prompt is requested lazily on the first download.
  Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      );
      await _plugin.initialize(settings: settings);
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.low,
        ),
      );
      _ready = true;
    } catch (error) {
      debugPrint('Download notifications unavailable: $error');
      _ready = false;
    }
  }

  /// Asks for notification permission once, when the user starts downloading.
  Future<void> ensurePermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    await ensureNotificationPermission();
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
        notificationDetails: NotificationDetails(
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
        return appL10n.typePlaylist;
      case DownloadItemType.album:
        return appL10n.typeAlbum;
      case DownloadItemType.artist:
        return appL10n.typeArtist;
      case DownloadItemType.favorites:
        return appL10n.typeFavorites;
    }
  }

  static String completionMessage(DownloadItem item) {
    if (item.type == DownloadItemType.favorites) {
      return appL10n.favoritesDownloaded;
    }
    return appL10n.downloadCompleted(typeLabel(item.type), item.title);
  }

  static String batchMessage(int count) {
    return appL10n.downloadCompletedBatch(count);
  }

  static String failureMessage(DownloadItem item) {
    if (item.type == DownloadItemType.favorites) {
      return appL10n.favoritesDownloadFailed;
    }
    return appL10n.downloadFailed(typeLabel(item.type), item.title);
  }

  static String batchBody(List<DownloadItem> items) {
    return items.map((item) => item.title).join(', ');
  }
}
