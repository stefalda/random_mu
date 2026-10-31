import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/services/cover_art_uri.dart';

void main() {
  group('carCoverArtUri', () {
    test('returns null without a cover', () {
      expect(carCoverArtUri(null), isNull);
      expect(carCoverArtUri(''), isNull);
    });

    test('builds a content URI the provider authority owns', () {
      final uri = carCoverArtUri('al-123');

      expect(uri.toString(), 'content://com.babisoft.random_mu.art/al-123');
      expect(uri!.scheme, 'content');
      expect(uri.host, carCoverArtAuthority);
      expect(uri.pathSegments.single, 'al-123');
    });

    test('keeps ids with separators in one path segment', () {
      // Subsonic ids may contain slashes and plus signs; Android decodes the
      // segment, so the cover id must round-trip untouched.
      const coverId = 'al/12 3+4=';
      final uri = carCoverArtUri(coverId)!;

      expect(uri.pathSegments, [coverId]);
      expect(uri.pathSegments.length, 1);
      expect(uri.toString(), contains('%2F'));
      expect(uri.toString(), isNot(contains('al/12')));
    });
  });

  group('coverArtIdOf', () {
    test('passes a plain cover id through', () {
      expect(coverArtIdOf('al-123'), 'al-123');
    });

    test('extracts the id from a cover URL', () {
      // `getAlbumList` expands the cover id into a full URL.
      const url = 'http://music.local/rest/getCoverArt.view?id=al-9&u=a&p=b';
      expect(coverArtIdOf(url), 'al-9');
    });

    test('returns null for a URL without a cover id', () {
      expect(coverArtIdOf('http://music.local/rest/ping.view'), isNull);
    });

    test('returns null when there is no cover', () {
      expect(coverArtIdOf(null), isNull);
      expect(coverArtIdOf(''), isNull);
    });
  });
}
