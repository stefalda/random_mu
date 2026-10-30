import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/l10n/generated/app_localizations.dart';

void main() {
  test('English is the template and Italian is translated', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final it = lookupAppLocalizations(const Locale('it'));

    expect(en.tabSongs, 'Songs');
    expect(it.tabSongs, 'Brani');
    expect(en.playbackShuffled, 'Shuffled playback');
    expect(it.playbackShuffled, 'Riproduzione casuale');
    expect(en.retry, 'Retry');
    expect(it.retry, 'Riprova');
  });

  test('plural and placeholder messages are translated', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final it = lookupAppLocalizations(const Locale('it'));

    expect(en.tracksCount(1), '1 track');
    expect(en.tracksCount(7), '7 tracks');
    expect(it.tracksCount(1), '1 brano');
    expect(it.tracksCount(7), '7 brani');

    expect(en.playlistCreated('Chill'), '"Chill" created');
    expect(it.playlistCreated('Chill'), '"Chill" creata');
    expect(it.emptySongsFor('queen'), 'Nessun brano per "queen"');
  });

  test('both locales are supported', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['en', 'it']),
    );
  });
}
