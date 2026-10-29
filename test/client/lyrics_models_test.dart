import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/client/subsonic_models.dart';

void main() {
  group('StructuredLyrics.fromJson', () {
    test('parses synced lines returned by Navidrome', () {
      final lyrics = StructuredLyrics.fromJson({
        'displayArtist': 'Calcutta',
        'displayTitle': 'Coro',
        'lang': 'xxx',
        'synced': true,
        'line': [
          {'start': 610, 'value': 'Se non esistessero i soldi'},
          {'start': 6080, 'value': 'Noi due dove saremmo?'},
        ],
      });

      expect(lyrics.displayArtist, 'Calcutta');
      expect(lyrics.synced, isTrue);
      expect(lyrics.hasTimings, isTrue);
      expect(lyrics.lines, hasLength(2));
      expect(lyrics.lines.first.start, 610);
      expect(lyrics.lines.last.value, 'Noi due dove saremmo?');
    });

    test('tolerates unsynced lyrics without start offsets', () {
      final lyrics = StructuredLyrics.fromJson({
        'synced': false,
        'line': [
          {'value': 'prima riga'},
          {'value': 'seconda riga'},
        ],
      });

      expect(lyrics.synced, isFalse);
      expect(lyrics.hasTimings, isFalse);
      expect(lyrics.lines.map((line) => line.start), [null, null]);
      expect(lyrics.lines.first.value, 'prima riga');
    });

    test('handles a missing line array', () {
      final lyrics = StructuredLyrics.fromJson({'synced': false});
      expect(lyrics.lines, isEmpty);
      expect(lyrics.hasTimings, isFalse);
    });
  });

  group('Lyrics.fromJson', () {
    test('parses the legacy plain lyrics payload', () {
      final lyrics = Lyrics.fromJson({
        'artist': 'Calcutta',
        'title': 'Coro',
        'value': 'Se non esistessero i soldi\nNoi due dove saremmo?',
      });

      expect(lyrics.artist, 'Calcutta');
      expect(lyrics.title, 'Coro');
      expect(lyrics.value.split('\n'), hasLength(2));
    });

    test('falls back to an empty value when the field is missing', () {
      final lyrics = Lyrics.fromJson({'artist': 'Calcutta'});
      expect(lyrics.value, isEmpty);
    });
  });
}
