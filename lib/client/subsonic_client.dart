/// subsonic_client.dart
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_mu/client/subsonic_models.dart';

class SubsonicClient {
  final String baseUrl;
  final String username;
  final String password;
  final String clientName;
  final String version = '1.16.1';

  SubsonicClient({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.clientName = 'DartClient',
  });

  Future<Map<String, dynamic>> _makeRequest(String endpoint,
      [Map<String, String>? params]) async {
    final queryParams = {
      'u': username,
      'p': password,
      'v': version,
      'c': clientName,
      'f': 'json',
      ...?params,
    };

    final uri = Uri.parse('$baseUrl/rest/$endpoint')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to make request: ${response.statusCode}');
    }

    String decodedResponse = utf8.decode(response.bodyBytes);

    // Now parse the JSON from the decoded string
    final jsonResponse = json.decode(decodedResponse);

    final subsonicResponse = jsonResponse['subsonic-response'];

    if (subsonicResponse['status'] != 'ok') {
      throw Exception(subsonicResponse['error']['message']);
    }

    return subsonicResponse;
  }

  // Music Library Methods
  Future<List<MusicFolder>> getMusicFolders() async {
    final response = await _makeRequest('getMusicFolders.view');
    final folders = response['musicFolders']['musicFolder'] as List;
    return folders.map((folder) => MusicFolder.fromJson(folder)).toList();
  }

  Future<IndexesResponse> getIndexes([String? musicFolderId]) async {
    final params =
        musicFolderId != null ? {'musicFolderId': musicFolderId} : null;
    final response = await _makeRequest('getIndexes.view', params);
    return IndexesResponse.fromJson(response['indexes']);
  }

  Future<Directory> getMusicDirectory(String id) async {
    final response = await _makeRequest('getMusicDirectory.view', {'id': id});
    return Directory.fromJson(response['directory']);
  }

  // Album/Artist Methods
  Future<List<Artist>> getArtists() async {
    final response = await _makeRequest('getArtists.view');
    return (response['artists']['index'] as List)
        .expand((index) => (index['artist'] as List))
        .map((artist) => Artist.fromJson(artist))
        .toList();
  }

  Future<Album> getAlbum(String id) async {
    final response = await _makeRequest('getAlbum.view', {'id': id});
    return Album.fromJson(response['album']);
  }

  String getCoverArtUrl(String? coverId) {
    if (coverId == null) return '';

    final params = {
      'id': coverId,
      'u': username,
      'p': password,
      'c': clientName,
      'v': version,
    };

    return Uri.parse('$baseUrl/rest/getCoverArt.view')
        .replace(queryParameters: params)
        .toString();
  }

  // Playlist Methods
  Future<List<Playlist>> getPlaylists() async {
    final response = await _makeRequest('getPlaylists.view');
    final playlists = response['playlists']['playlist'] as List;
    return playlists.map((playlist) => Playlist.fromJson(playlist)).toList();
  }

  Future<List<Song>> getPlaylistSongs(String id) async {
    final response = await _makeRequest('getPlaylist.view', {'id': id});
    final playlistWithSongs = PlaylistWithSongs.fromJson(response['playlist']);
    return playlistWithSongs.songs;
  }

  Future<List<Song>> getArtistSongsRandomized(String artistId,
      {int? count}) async {
    final artist = await _makeRequest('getArtist.view', {'id': artistId});
    List<Song> allSongs = [];

    // Get songs from all albums
    for (var album in artist['artist']['album'] as List) {
      final albumDetails = await getAlbum(album['id']);
      allSongs.addAll(albumDetails.songs);
    }

    // Randomize songs
    allSongs.shuffle();

    // Return requested count or all songs if count not specified
    return count != null ? allSongs.take(count).toList() : allSongs;
  }

  Future<List<ArtistSearchResult>> searchArtists(String query) async {
    final response = await _makeRequest('search3.view', {'query': query});
    final artists = response['searchResult3']['artist'] as List? ?? [];
    return artists
        .map((artist) => ArtistSearchResult.fromJson(artist))
        .toList();
  }

  Future<Map<String, List<Song>>> getMultipleArtistsSongs(
      List<String> artistIds,
      {bool randomize = false}) async {
    final results = await Future.wait(
        artistIds.map((id) => getArtistSongsRandomized(id, count: null)));

    return Map.fromIterables(
        artistIds,
        results.map((songs) =>
            randomize ? (List<Song>.from(songs)..shuffle()) : songs));
  }

  Future<List<Song>> getSimilarSongs(String songOrAlbumOrArtistId,
      {count = 50}) async {
    try {
      final response = await _makeRequest('getSimilarSongs.view',
          {'id': songOrAlbumOrArtistId, 'count': count.toString()});
      final similarSongs = response['similarSongs']['song'] as List<dynamic>;
      return similarSongs.map((song) => Song.fromJson(song)).toList();
    } catch (_) {
      // Something went wrong
      return [];
    }
  }

  String getStreamUrl(
    String songId, {
    String format = 'mp3',
    int? maxBitRate,
    int? timeOffset,
  }) {
    final params = {
      'id': songId,
      'format': format,
      'u': username,
      'p': password,
      'c': clientName,
      'v': version,
      if (maxBitRate != null) 'maxBitRate': maxBitRate.toString(),
      if (timeOffset != null) 'timeOffset': timeOffset.toString(),
    };

    final uri =
        Uri.parse('$baseUrl/rest/stream.view').replace(queryParameters: params);

    return uri.toString();
  }

  /// Gets a list of random songs from the Subsonic server.
  ///
  /// Parameters:
  /// - [count] The number of songs to return (required)
  /// - [genre] Only returns songs belonging to this genre
  /// - [fromYear] Only returns songs after or in this year
  /// - [toYear] Only returns songs before or in this year
  /// - [musicFolderId] Only returns songs from this music folder
  Future<List<Song>> getRandomSongs({
    required int count,
    String? genre,
    int? fromYear,
    int? toYear,
    String? musicFolderId,
  }) async {
    final params = {
      'size': count.toString(),
      if (genre != null) 'genre': genre,
      if (fromYear != null) 'fromYear': fromYear.toString(),
      if (toYear != null) 'toYear': toYear.toString(),
      if (musicFolderId != null) 'musicFolderId': musicFolderId,
    };

    final response = await _makeRequest('getRandomSongs', params);

    // The response will contain a 'randomSongs' object with a 'song' array
    final songs = response['randomSongs']['song'] as List<dynamic>;

    return songs.map((songData) => Song.fromJson(songData)).toList();
  }

  /// Gets all genres from the Subsonic server.
  /// Returns a list of genres with their song and album counts.
  Future<List<Genre>> getGenres() async {
    final response = await _makeRequest('getGenres');

    // The response will contain a 'genres' object with a 'genre' array
    final genres = response['genres']['genre'] as List<dynamic>;

    return genres.map((genreData) => Genre.fromJson(genreData)).toList();
  }

  /// Searches for artists, albums, and songs using Subsonic's search3 endpoint.
  ///
  /// Parameters:
  /// - [query] The search query (required)
  /// - [artistCount] Maximum number of artists to return
  /// - [artistOffset] Artists search offset
  /// - [albumCount] Maximum number of albums to return
  /// - [albumOffset] Albums search offset
  /// - [songCount] Maximum number of songs to return
  /// - [songOffset] Songs search offset
  Future<SearchResult> search({
    required String query,
    int? artistCount,
    int? artistOffset,
    int? albumCount,
    int? albumOffset,
    int? songCount,
    int? songOffset,
  }) async {
    final params = {
      'query': query,
      if (artistCount != null) 'artistCount': artistCount.toString(),
      if (artistOffset != null) 'artistOffset': artistOffset.toString(),
      if (albumCount != null) 'albumCount': albumCount.toString(),
      if (albumOffset != null) 'albumOffset': albumOffset.toString(),
      if (songCount != null) 'songCount': songCount.toString(),
      if (songOffset != null) 'songOffset': songOffset.toString(),
    };

    final response = await _makeRequest('search3', params);
    return SearchResult.fromJson(response, parentName: 'searchResult3');
  }

  Future<List<Song>> getSongsByGenre(
      {required int count, String? genre}) async {
    final params = {
      'count': count.toString(),
      if (genre != null) 'genre': genre,
    };

    final response = await _makeRequest('getSongsByGenre', params);

    // The response will contain a 'randomSongs' object with a 'song' array
    final songs = response['songsByGenre']['song'] as List<dynamic>;

    return songs.map((songData) => Song.fromJson(songData)).toList();
  }

  Future<SearchResult> getStarred({String? musicFolderId}) async {
    final params = {
      if (musicFolderId != null) 'musicFolderId': musicFolderId,
    };

    final response = await _makeRequest('getStarred2', params);

    return SearchResult.fromJson(response, parentName: 'starred2');
  }

// Usage example:
// final streamUrl = client.getStreamUrl(song.id);
// Use streamUrl with any audio player library, e.g.:
// final player = AudioPlayer();
// await player.play(UrlSource(streamUrl));

  /// Ping the server
  Future<bool> ping() async {
    try {
      await _makeRequest('ping', {});

      return true;
    } catch (ex) {
      debugPrint("Error: $ex");
      return false;
    }
  }
}
