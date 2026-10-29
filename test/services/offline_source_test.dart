import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/services/offline_source.dart';

MediaItem _item({String? streamUrl}) => MediaItem(
      id: 'song-1',
      title: 'Song',
      extras: streamUrl == null ? null : {'streamUrl': streamUrl},
    );

void main() {
  group('resolveSongUri', () {
    test('uses the downloaded file when it exists', () {
      final uri = resolveSongUri(
        mediaItem: _item(streamUrl: 'https://server/rest/stream.view?id=song-1'),
        localPath: '/data/user/0/app/app_flutter/offline_music/song-1.flac',
      );

      expect(uri.scheme, 'file');
      expect(uri.toFilePath(),
          '/data/user/0/app/app_flutter/offline_music/song-1.flac');
    });

    test('streams when there is no local copy', () {
      final uri = resolveSongUri(
        mediaItem: _item(streamUrl: 'https://server/rest/stream.view?id=song-1'),
      );

      expect(uri.toString(), 'https://server/rest/stream.view?id=song-1');
    });

    test('ignores an empty local path and streams', () {
      final uri = resolveSongUri(
        mediaItem: _item(streamUrl: 'https://server/rest/stream.view?id=song-1'),
        localPath: '',
      );

      expect(uri.scheme, 'https');
    });

    test('reports a media item without a stream URL', () {
      expect(
        () => resolveSongUri(mediaItem: _item()),
        throwsArgumentError,
      );
    });
  });
}
