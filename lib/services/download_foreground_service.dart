import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/download_service.dart';

/// Bridge to the native (Kotlin) download foreground service.
///
/// The queue stays in the Dart isolate; the native service only keeps the
/// process alive, shows progress in a persistent notification and forwards the
/// notification's "Pause" action back to Dart.
class DownloadForegroundService {
  DownloadForegroundService(this.downloadService) {
    downloadService.addListener(_sync);
    if (isSupported) {
      _channel.setMethodCallHandler(_handleNativeCall);
      _lifecycleListener = AppLifecycleListener(onStateChange: _onLifecycle);
    }
  }

  static const MethodChannel _channel =
      MethodChannel('com.babisoft.randommu/downloads');

  final DownloadService downloadService;

  bool _running = false;
  bool _starting = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  AppLifecycleListener? _lifecycleListener;

  /// The native service only exists on Android.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  @visibleForTesting
  bool get isRunning => _running;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'pause') downloadService.pauseQueue();
    return null;
  }

  bool get _canStartForeground =>
      _lifecycle == AppLifecycleState.resumed ||
      _lifecycle == AppLifecycleState.inactive;

  void _onLifecycle(AppLifecycleState state) {
    _lifecycle = state;
    if (_canStartForeground) _sync();
  }

  void _sync() {
    if (!isSupported) return;
    unawaited(_syncAsync());
  }

  Future<void> _syncAsync() async {
    final hasWork = downloadService.queue.any((item) =>
        item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.downloading);

    if (hasWork && !_running && !_starting && _canStartForeground) {
      _starting = true;
      try {
        await _channel.invokeMethod<void>('start', _payload());
        _running = true;
      } catch (error) {
        debugPrint('Cannot start the download foreground service: $error');
        _running = false;
      } finally {
        _starting = false;
      }
    } else if (!hasWork && _running) {
      _running = false;
      try {
        await _channel.invokeMethod<void>('stop');
      } catch (error) {
        debugPrint('Cannot stop the download foreground service: $error');
      }
    }

    if (hasWork && _running) await _updateNotification();
  }

  Future<void> _updateNotification() async {
    try {
      await _channel.invokeMethod<void>('update', _payload());
    } catch (error) {
      debugPrint('Cannot update the download notification: $error');
    }
  }

  Map<String, dynamic> _payload() {
    final queue = downloadService.queue;
    final completed =
        queue.where((item) => item.status == DownloadStatus.completed).length;
    final downloading = queue
        .where((item) => item.status == DownloadStatus.downloading)
        .toList();

    final title = downloadService.isPaused
        ? 'Downloads paused'
        : downloading.isEmpty
            ? 'Downloading'
            : 'Downloading "${downloading.first.title}"';

    return {
      'title': title,
      'text': '$completed/${queue.length} downloads complete',
    };
  }

  void dispose() {
    downloadService.removeListener(_sync);
    _lifecycleListener?.dispose();
  }
}
