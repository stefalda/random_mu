import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/download_service.dart';

/// Notification channel/id of the download foreground service.
///
/// Separate from the audio playback channel owned by `AudioService`.
const String backgroundDownloadChannelId = 'random_mu_downloads_service';
const int backgroundDownloadNotificationId = 8899;

/// Entry point of the download foreground service isolate.
///
/// The queue itself lives in the main isolate; this service keeps the app
/// process (and therefore the queue) alive and mirrors progress in the
/// persistent notification.
@pragma('vm:entry-point')
void backgroundDownloadEntryPoint(ServiceInstance service) {
  service.on('updateProgress').listen((event) {
    if (service is AndroidServiceInstance && event != null) {
      service.setForegroundNotificationInfo(
        title: event['title'] as String? ?? 'Downloading',
        content: event['content'] as String? ?? '',
      );
    }
  });

  service.on('stopService').listen((_) {
    service.stopSelf();
  });
}

/// Starts and stops the foreground service around download activity.
class BackgroundDownloadKeeper {
  final DownloadService downloadService;

  bool _configured = false;
  bool _running = false;
  StreamSubscription<dynamic>? _pauseSubscription;

  BackgroundDownloadKeeper(this.downloadService) {
    downloadService.addListener(_sync);
    unawaited(_configure());
  }

  /// The background service only exists on Android.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  @visibleForTesting
  bool get isRunning => _running;

  Future<void> _configure() async {
    if (!isSupported) return;
    try {
      final service = FlutterBackgroundService();
      _configured = await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: backgroundDownloadEntryPoint,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: backgroundDownloadChannelId,
          initialNotificationTitle: 'Random Muu',
          initialNotificationContent: 'Preparing downloads',
          foregroundServiceNotificationId: backgroundDownloadNotificationId,
          foregroundServiceTypes: const [AndroidForegroundType.dataSync],
        ),
        iosConfiguration: IosConfiguration(autoStart: false),
      );
      _pauseSubscription = service
          .on('pauseDownloads')
          .listen((_) => downloadService.pauseQueue());
    } catch (error) {
      debugPrint('Download foreground service unavailable: $error');
      _configured = false;
    }
  }

  /// Keeps the service in sync with the queue state.
  void _sync() {
    if (!_configured) return;

    final hasWork = downloadService.queue.any((item) =>
        item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.downloading);

    if (hasWork && !_running) {
      _running = true;
      FlutterBackgroundService().startService();
    } else if (!hasWork && _running) {
      _running = false;
      FlutterBackgroundService().invoke('stopService');
    }

    if (hasWork) _updateNotification();
  }

  void _updateNotification() {
    final queue = downloadService.queue;
    final completed =
        queue.where((item) => item.status == DownloadStatus.completed).length;
    final downloading = queue
        .where((item) => item.status == DownloadStatus.downloading)
        .toList();

    final title = downloading.isEmpty
        ? 'Downloading'
        : 'Downloading "${downloading.first.title}"';

    FlutterBackgroundService().invoke('updateProgress', {
      'title': title,
      'content': '$completed/${queue.length} downloads complete',
    });
  }

  void dispose() {
    downloadService.removeListener(_sync);
    _pauseSubscription?.cancel();
  }
}
