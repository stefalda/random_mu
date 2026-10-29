import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inject_x/inject_x.dart';
import 'package:random_mu/services/download_service.dart';

/// Shared [DownloadService] instance, registered with InjectX in `main.dart`.
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return inject<DownloadService>();
});
