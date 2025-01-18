// MediaItem factory for just_audio_background support
import 'package:just_audio_background/just_audio_background.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/client/subsonic_models.dart';

MediaItem createMediaItem(Song song, SubsonicClient client) {
  return MediaItem(
      id: song.id,
      album: song.album ?? '',
      title: song.title,
      artist: song.artist ?? '',
      duration:
          song.duration != null ? Duration(seconds: song.duration!) : null,
      artUri: song.coverArt != null
          ? Uri.parse(client.getCoverArtUrl(song.coverArt))
          : null,
      extras: {
        'streamUrl': client.getStreamUrl(song.id),
        'contentType': song.contentType,
        'size': song.size,
        'path': song.path,
      });
}
