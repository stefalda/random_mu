import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/client/subsonic_models.dart';

void main() {
  group('Song.starred', () {
    Map<String, dynamic> songJson({Object? starred}) => {
          'id': 's1',
          'isDir': false,
          'title': 'Closing Time',
          'starred': starred,
        };

    test('parses the starred timestamp', () {
      final song = Song.fromJson(songJson(starred: '2026-10-30T09:00:00Z'));
      expect(song.starred, isNotNull);
      expect(song.starred!.toUtc().year, 2026);
    });

    test('is null for a song that is not starred', () {
      expect(Song.fromJson(songJson()).starred, isNull);
    });

    test('a malformed value does not throw', () {
      expect(Song.fromJson(songJson(starred: 'not-a-date')).starred, isNull);
    });
  });
}
