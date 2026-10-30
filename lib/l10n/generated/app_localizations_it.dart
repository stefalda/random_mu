// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get create => 'Crea';

  @override
  String get delete => 'Elimina';

  @override
  String get rename => 'Rinomina';

  @override
  String get retry => 'Riprova';

  @override
  String get reload => 'Ricarica';

  @override
  String get remove => 'Rimuovi';

  @override
  String get close => 'Chiudi';

  @override
  String get navLibrary => 'Libreria';

  @override
  String get navPlaylists => 'Playlist';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navSearch => 'Cerca';

  @override
  String get tabArtists => 'Artisti';

  @override
  String get tabAlbums => 'Album';

  @override
  String get tabSongs => 'Brani';

  @override
  String get tabFavorites => 'Preferiti';

  @override
  String get tabGenres => 'Generi';

  @override
  String get searchArtistsHint => 'Cerca artisti…';

  @override
  String get searchAlbumsHint => 'Cerca album…';

  @override
  String get searchSongsHint => 'Cerca brani…';

  @override
  String get searchPlaylistsHint => 'Cerca playlist…';

  @override
  String get searchEverythingHint => 'Cerca artisti, album, brani…';

  @override
  String get searchLibraryHint => 'Cerca nella libreria';

  @override
  String get searchingAlbums => 'Cerco album…';

  @override
  String get searchingSongs => 'Cerco brani…';

  @override
  String get loadingSongs => 'Carico i brani…';

  @override
  String get loadingPlaylists => 'Caricamento playlist…';

  @override
  String get emptyArtists => 'Nessun artista disponibile';

  @override
  String get emptyAlbums => 'Nessun album disponibile';

  @override
  String emptyAlbumsFor(String query) {
    return 'Nessun album per \"$query\"';
  }

  @override
  String get emptySongs => 'Nessun brano nella libreria';

  @override
  String emptySongsFor(String query) {
    return 'Nessun brano per \"$query\"';
  }

  @override
  String get emptyGenres => 'Nessun genere';

  @override
  String get emptyFavorites => 'Nessun preferito';

  @override
  String get emptyResults => 'Nessun risultato';

  @override
  String get emptyPlaylist => 'Playlist vuota';

  @override
  String get emptyAlbum => 'Album senza brani';

  @override
  String get emptyArtist => 'Nessun album per questo artista';

  @override
  String get emptyGenre => 'Nessun brano per questo genere';

  @override
  String get noSongPlaying => 'Nessun brano in riproduzione';

  @override
  String get randomCommands => 'Casuale';

  @override
  String get randomCommandsTooltip => 'Comandi casuali una-tantum';

  @override
  String get allRandom => 'Tutto casuale';

  @override
  String get randomByPlaying => 'Casuale dal brano';

  @override
  String get randomByFavorites => 'Casuale dai preferiti';

  @override
  String get play => 'Riproduci';

  @override
  String get playAll => 'Riproduci tutto';

  @override
  String get playNow => 'Riproduci ora';

  @override
  String get playNext => 'Riproduci dopo';

  @override
  String get queue => 'Accoda';

  @override
  String get addToPlaylist => 'Aggiungi a playlist…';

  @override
  String get addTo => 'Aggiungi a…';

  @override
  String get newPlaylist => 'Nuova playlist';

  @override
  String get newPlaylistEllipsis => 'Nuova playlist…';

  @override
  String get playlistName => 'Nome playlist';

  @override
  String get lyrics => 'Testo';

  @override
  String get lyricsEmpty => 'Nessun testo disponibile per questo brano.';

  @override
  String lyricsError(String error) {
    return 'Impossibile caricare il testo: $error';
  }

  @override
  String get modeSequential => 'Sequenziale';

  @override
  String get modeShuffled => 'Casuale';

  @override
  String get playbackSequential => 'Riproduzione sequenziale';

  @override
  String get playbackShuffled => 'Riproduzione casuale';

  @override
  String playbackModeTooltip(String mode) {
    return 'Riproduzione $mode';
  }

  @override
  String get addedToQueue => 'Aggiunto alla coda';

  @override
  String get playingNext => 'In riproduzione dopo questo brano';

  @override
  String get albumAddedToQueue => 'Album aggiunto alla coda';

  @override
  String get playlistAddedToQueue => 'Playlist aggiunta alla coda';

  @override
  String get tracksAddedToQueue => 'Brani aggiunti alla coda';

  @override
  String get similarSongsQueue => 'Coda sostituita con brani simili';

  @override
  String get similarSongsTooltip => 'Brani simili (Play Similar)';

  @override
  String similarSongsError(String error) {
    return 'Impossibile trovare brani simili: $error';
  }

  @override
  String get addToFavorites => 'Aggiungi ai preferiti';

  @override
  String get removeFromFavorites => 'Rimuovi dai preferiti';

  @override
  String favoriteAddFailed(String error) {
    return 'Impossibile aggiungere ai preferiti: $error';
  }

  @override
  String favoriteRemoveFailed(String error) {
    return 'Impossibile rimuovere dai preferiti: $error';
  }

  @override
  String get albumAddedToFavorites => 'Album aggiunto ai preferiti';

  @override
  String get albumRemovedFromFavorites => 'Album rimosso dai preferiti';

  @override
  String favoritesUpdateFailed(String error) {
    return 'Impossibile aggiornare i preferiti: $error';
  }

  @override
  String playlistCreated(String name) {
    return '\"$name\" creata';
  }

  @override
  String playlistDeleted(String name) {
    return '\"$name\" eliminata';
  }

  @override
  String playlistRenamed(String name) {
    return 'Playlist rinominata in \"$name\"';
  }

  @override
  String playlistCreateFailed(String error) {
    return 'Impossibile creare la playlist: $error';
  }

  @override
  String playlistRenameFailed(String error) {
    return 'Impossibile rinominare la playlist: $error';
  }

  @override
  String playlistDeleteFailed(String error) {
    return 'Impossibile eliminare la playlist: $error';
  }

  @override
  String playlistAddFailed(String error) {
    return 'Impossibile aggiungere alla playlist: $error';
  }

  @override
  String playlistLoadFailed(String error) {
    return 'Impossibile caricare la playlist: $error';
  }

  @override
  String get deletePlaylistTitle => 'Eliminare la playlist?';

  @override
  String deletePlaylistBody(String name) {
    return '\"$name\" verrà eliminata da Navidrome. I brani restano nella libreria.';
  }

  @override
  String get renamePlaylist => 'Rinomina playlist';

  @override
  String get removeFromPlaylist => 'Rimuovi dalla playlist';

  @override
  String trackRemoved(String title) {
    return '\"$title\" rimosso';
  }

  @override
  String trackRemoveFailed(String error) {
    return 'Impossibile rimuovere il brano: $error';
  }

  @override
  String playlistUnavailable(String error) {
    return 'Playlist non disponibili: $error';
  }

  @override
  String get managePlaylist => 'Gestisci playlist';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String songsAndAlbums(String songs, String albums) {
    return '$songs · $albums';
  }

  @override
  String get allTracks => 'Tutti i brani';

  @override
  String albumLoadFailed(String error) {
    return 'Impossibile caricare l\'album: $error';
  }

  @override
  String artistLoadFailed(String error) {
    return 'Impossibile caricare l\'artista: $error';
  }

  @override
  String songsLoadFailed(String error) {
    return 'Impossibile caricare i brani: $error';
  }

  @override
  String genresLoadFailed(String error) {
    return 'Impossibile caricare i generi: $error';
  }

  @override
  String favoritesLoadFailed(String error) {
    return 'Impossibile caricare i preferiti: $error';
  }

  @override
  String searchFailed(String error) {
    return 'Ricerca fallita: $error';
  }

  @override
  String get unknownArtist => 'Artista sconosciuto';

  @override
  String get unknownAlbum => 'Album sconosciuto';

  @override
  String yearAndTracks(String year, String tracks) {
    return '$year · $tracks';
  }

  @override
  String albumsLoadFailed(String error) {
    return 'Impossibile caricare gli album: $error';
  }

  @override
  String artistsLoadFailed(String error) {
    return 'Impossibile caricare gli artisti: $error';
  }

  @override
  String emptyArtistsFor(String query) {
    return 'Nessun artista per \"$query\"';
  }

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get pauseDownloads => 'Metti in pausa i download';

  @override
  String get resumeDownloads => 'Riprendi i download';

  @override
  String get removeDownload => 'Rimuovi download';

  @override
  String get removeDownloadTitle => 'Rimuovere il download?';

  @override
  String removeDownloadBody(String title) {
    return 'Rimuovere \"$title\" e i suoi file scaricati da questo dispositivo?';
  }

  @override
  String get clearAllDownloads => 'Rimuovi tutti i download';

  @override
  String get clearAll => 'Rimuovi tutto';

  @override
  String get downloadQueued => 'In coda';

  @override
  String downloadingProgress(String percent, int done, int total) {
    return 'Download $percent% ($done/$total)';
  }

  @override
  String downloadingPercent(String percent) {
    return 'Download $percent%';
  }

  @override
  String downloadFailedWith(String error) {
    return 'Fallito: $error';
  }

  @override
  String get noDownloadsYet => 'Nessun download';

  @override
  String get storage => 'Spazio';

  @override
  String get storageLimit => 'Limite di spazio';

  @override
  String usedOfLimit(String used, String limit) {
    return 'Usati: $used / Limite: $limit';
  }

  @override
  String get unlimited => 'Illimitato';

  @override
  String get downloadForOffline => 'Scarica per l\'offline';

  @override
  String get downloadedTapToRemove => 'Scaricato - tocca per rimuovere';

  @override
  String get downloadFailedTapToRetry =>
      'Download fallito - tocca per riprovare';

  @override
  String get favoritesDownloaded => 'Preferiti scaricati';

  @override
  String get favoritesDownloadFailed => 'Download dei preferiti fallito';

  @override
  String get offlineDownloadChannel =>
      'Avanzamento e risultati dei download offline';

  @override
  String get connectTitle => 'Connettiti al server Subsonic';

  @override
  String get serverUrl => 'URL del server';

  @override
  String get username => 'Nome utente';

  @override
  String get password => 'Password';

  @override
  String get connect => 'Connetti';

  @override
  String get pleaseEnterServerUrl => 'Inserisci l\'URL del server';

  @override
  String get pleaseEnterUsername => 'Inserisci il nome utente';

  @override
  String get pleaseEnterPassword => 'Inserisci la password';

  @override
  String get invalidUrlFormat => 'Formato URL non valido';

  @override
  String get invalidServerUrl => 'URL del server non valido';

  @override
  String get pleaseEnterValidUrl => 'Inserisci un URL valido';

  @override
  String get storageLimitReached =>
      'Limite di spazio raggiunto. Libera spazio per scaricare altro.';

  @override
  String get retryDownload => 'Riprova';

  @override
  String get downloadsHeader => 'Downloads';

  @override
  String get clearAllDownloadsBody =>
      'Rimuoverà tutti i contenuti scaricati e libererà spazio.';

  @override
  String get unknownError => 'Errore sconosciuto';

  @override
  String get clearAllDownloadsTitle => 'Rimuovi tutti i download';

  @override
  String get tabPlaylists => 'Playlist';

  @override
  String downloadCompleted(String type, String title) {
    return '$type \'$title\' scaricato';
  }

  @override
  String downloadCompletedBatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count download completati',
      one: '1 download completato',
    );
    return '$_temp0';
  }

  @override
  String downloadFailed(String type, String title) {
    return 'Download di $type \'$title\' fallito';
  }

  @override
  String get typePlaylist => 'Playlist';

  @override
  String get typeAlbum => 'Album';

  @override
  String get typeArtist => 'Artista';

  @override
  String get typeFavorites => 'Preferiti';

  @override
  String playlistsLoadFailed(String error) {
    return 'Impossibile caricare le playlist: $error';
  }

  @override
  String get emptyPlaylists => 'Nessuna playlist disponibile';

  @override
  String playlistsEmptyFor(String query) {
    return 'Nessuna playlist per \"$query\"';
  }

  @override
  String get allFieldsRequired => 'Tutti i campi sono obbligatori';

  @override
  String get offlineShowingDownloads =>
      'Server non raggiungibile: mostro i contenuti scaricati';

  @override
  String get offlineEmpty =>
      'Server non raggiungibile e nessun contenuto scaricato';

  @override
  String get offlineBanner => 'Offline';

  @override
  String downloadedSummary(int done, int total) {
    return 'Scaricato ($done/$total)';
  }

  @override
  String get errorNoConnection => 'Server non raggiungibile';

  @override
  String get errorTimeout => 'Il server non risponde';

  @override
  String errorServer(String status) {
    return 'Errore del server ($status)';
  }

  @override
  String get errorUnexpected => 'Errore imprevisto';

  @override
  String errorWithDetail(String detail) {
    return 'Errore: $detail';
  }

  @override
  String get removeFromQueue => 'Rimuovi dalla coda';

  @override
  String get removedFromQueue => 'Rimosso dalla coda';
}
