import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:inject_x/inject_x.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_mu/client/just_audio_client.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/services/preference_service.dart';

const defaultCount = 50;

class PlayerService extends ChangeNotifier {
  final String serverUrl;
  final String username;
  final String password;

  final audioPlayer = AudioPlayer();
  //late AudioPlayerHandler audioPlayerHandler;
  late SubsonicClient client;
  StreamSubscription<int?>? _indexSubscription;

  int _lastPlayingSongIndex = 0;

  PlayerService(
      {required this.serverUrl,
      required this.username,
      required this.password}) {
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    // Connect
    client = SubsonicClient(
      baseUrl: serverUrl,
      username: username,
      password: password,
    );
    // Listen for song index changes and store in preferences...
    _indexSubscription = audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        debugPrint('Now playing track at index: $index');
        if (_lastPlayingSongIndex != index) {
          _lastPlayingSongIndex = index;
          final PreferenceService ps = inject<PreferenceService>();
          ps.storeCurrentPlayingSong(index);
        }
      }
    });

    //await restoreSongs();
  }

  @override
  dispose() {
    _indexSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<List<Genre>> getGenres() async {
    final genres = await client.getGenres();
    for (var genre in genres) {
      debugPrint(genre.name);
    }
    return genres;
  }

  Future<List<Artist>> getArtists() async {
    final artists = await client.getArtists();
    /*for (var artist in artists) {
      debugPrint("${artist.name} - ${artist.artistImageUrl}");
    }*/
    return artists;
  }

  Future<List<Album>> getAlbums() async {
    final albums =
        await client.getAllAlbumsList(type: AlbumListType.alphabeticalByName);
    return albums;
  }

  Future<List<Playlist>> getPlaylists() async {
    final playlists = await client.getPlaylists();
    for (var playlist in playlists) {
      debugPrint(playlist.name);
    }
    return playlists;
  }

  Future randomAll({String? genre, count = defaultCount}) async {
    //await getGenres();
    //genre = "Cantautori Italiani";
    //await getArtists();
    //final result = await client.getStarred();
    //await _enqueueSongs(result.songs);

    final randomSongs = await client.getRandomSongs(count: count, genre: genre);
    await _enqueueSongs(randomSongs);
  }

  ///
  ///  Restore previous session playng song list
  ///
  Future restoreSongs() async {
    final PreferenceService ps = inject<PreferenceService>();
    final List<Song>? songs = await ps.retrieveLatestPlaylist();
    if (songs != null) {
      final songIndex = await ps.retrieveCurrentPlayingSongIndex();
      await _enqueueSongs(songs, songIndex: songIndex);
    }
  }

  /// Return all the favorited songs and songs in favorited albums
  Future randomFavorites({int count = defaultCount}) async {
    final searchResult = await client.getStarred();
    final starredSongs = searchResult.songs;
    for (Album album in searchResult.albums) {
      final albumDetail = await client.getAlbum(album.id);
      starredSongs.addAll(albumDetail.songs);
      starredSongs.shuffle();
    }
    starredSongs.shuffle();
    await _enqueueSongs(starredSongs);
  }

  Future randomByArtist(
      {required String artistId, count = defaultCount}) async {
    final randomSongs =
        await client.getArtistSongsRandomized(artistId, count: count);

    await _enqueueSongs(randomSongs);
  }

  Future randomByAlbum({required String albumId}) async {
    final randomSongs = await client.getSongsByAlbum(albumId: albumId);
    randomSongs.shuffle();
    await _enqueueSongs(randomSongs);
  }

  Future randomByPlaylist({required String playlistId}) async {
    final randomSongs = await client.getPlaylistSongs(playlistId);
    randomSongs.shuffle();
    await _enqueueSongs(randomSongs);
  }

  Future randomByPlayingSong() async {
    final playingSongIndex = audioPlayer.currentIndex;
    if (playingSongIndex == null) return;
    final AudioSource playingSong = audioPlayer.audioSources[playingSongIndex];
    //audioPlayer.audioSource!.sequence.elementAt(playingSongIndex);
    final String currentSongId = (playingSong as ProgressiveAudioSource).tag.id;
    final similarSongs = await client.getSimilarSongs(currentSongId);
    if (similarSongs.isEmpty) return;
    // Check if the source soung is included
    late Song currentSong;
    int idx = similarSongs.indexWhere((song) => song.id == currentSongId);
    if (idx >= 0) {
      debugPrint("Current playing song index in new List = $idx");
      currentSong = similarSongs[idx];
      similarSongs.removeAt(idx);
    } else {
      final json = jsonDecode(playingSong.tag.extras['songJson']);
      currentSong = Song.fromJson(json);
    }
    // Move in first
    similarSongs.insert(0, currentSong);
    Duration? position;
    if (audioPlayer.playing) {
      position = await audioPlayer.positionStream.first;
    }
    await _enqueueSongs(similarSongs, restartAt: position);
  }

  Future<void> _enqueueSongs(List<Song> songs,
      {Duration? restartAt, songIndex = 0}) async {
    // for (var randomSong in songs) {
    //   debugPrint(randomSong.title);
    // }
    final audioSources = songs
        .map((song) => createMediaItem(song, client))
        .map((mediaItem) => AudioSource.uri(
            Uri.parse(mediaItem.extras!['streamUrl']),
            tag: mediaItem))
        .toList();
    debugPrint("AudioSources enqueued: ${audioSources.length}");
    // Set up a playlist with metadata.
    //final AudioSource playlist = ConcatenatingAudioSource(
    //    children: audioSources, useLazyPreparation: true);
    if (audioPlayer.playing) {
      await audioPlayer.stop();
    }
    //await audioPlayer.setAudioSources(audioSources, initialPosition: restartAt);
    //await audioPlayer.setAudioSource(playlist, initialPosition: restartAt);
    await audioPlayer.setAudioSources(
      audioSources,
      initialIndex: songIndex, // Which track to start with (0-based)
      initialPosition: restartAt,
    );
    // Play
    unawaited(play());
    // Store in preferences the current audio sources...
    final PreferenceService ps = inject<PreferenceService>();
    await ps.storeLatestPlaylist(songs);
  }

  Future<String> fetchData() async {
    await Future.delayed(Duration(seconds: 2)); // Simula un ritardo
    return "Dati caricati dall'API!";
  }

  Future play() async {
    //await audioPlayerHandler.play();
    await audioPlayer.play();
  }

  Future pause() async {
    await audioPlayer.pause();
  }

  Future previous() async {
    await audioPlayer.seekToPrevious();
  }

  Future next() async {
    await audioPlayer.seekToNext();
  }

  bool isPlaying() {
    return audioPlayer.playing;
  }

  Future updatePlayingInfo(MediaItem mediaItem) async {
    // if (kIsWeb) return;
    // await audioPlayerHandler.updateMediaMetadata(
    //   title: mediaItem.title,
    //   artist: mediaItem.artist ?? 'Unknown Artist',
    //   album: mediaItem.album ?? 'Unknown Album',
    //   artworkUri: mediaItem.artUri.toString(),
    //   duration: mediaItem.duration,
    // );
  }

  /*xw

// Get music folders
    final artists = await client.searchArtists("Mor");
    debugPrint("Artists: ${artists.length}");
    for (var artist in artists) {
      debugPrint(" ${artist.name} - ${artist.id}");
    }
    // Get all songs by an artist
    final artistId = "ac92d51e195168f06754633327663964";
    final randomSongs =
        await client.getArtistSongsRandomized(artistId, count: defaultCount);
    for (var randomSong in randomSongs) {
      debugPrint(randomSong.title);
    }
    // Play the first song
    final player = AudioPlayer();
    final mediaItem = createMediaItem(randomSongs.first, client);
    await player.setAudioSource(AudioSource.uri(
      Uri.parse(mediaItem.extras!['streamUrl']),
      tag: mediaItem,
    ));
    await player.play();

// Get playlist
//final playlist = await client.getPlaylist('playlist-id');
*/
}
