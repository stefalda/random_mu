import 'package:audio_service/audio_service.dart';

/// Chooses the audio source for a song.
///
/// Downloaded songs are played from the local file; everything else streams from
/// the Subsonic server. The choice is transparent to the caller: both the phone
/// app and Android Auto go through it.
Uri resolveSongUri({
  required MediaItem mediaItem,
  String? localPath,
}) {
  if (localPath != null && localPath.isNotEmpty) {
    return Uri.file(localPath);
  }
  final streamUrl = mediaItem.extras?['streamUrl'] as String?;
  if (streamUrl == null || streamUrl.isEmpty) {
    throw ArgumentError('MediaItem ${mediaItem.id} has no stream URL');
  }
  return Uri.parse(streamUrl);
}
