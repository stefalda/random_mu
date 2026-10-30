// Add new model class:
class ArtistSearchResult {
  final String id;
  final String name;
  final int albumCount;

  ArtistSearchResult({
    required this.id,
    required this.name,
    required this.albumCount,
  });

  factory ArtistSearchResult.fromJson(Map<String, dynamic> json) {
    return ArtistSearchResult(
      id: json['id'],
      name: json['name'],
      albumCount: json['albumCount'],
    );
  }
}

// Data Models
class MusicFolder {
  final String id;
  final String? name;

  MusicFolder({required this.id, this.name});

  factory MusicFolder.fromJson(Map<String, dynamic> json) {
    return MusicFolder(
      id: json['id'].toString(),
      name: json['name'],
    );
  }
}

class IndexesResponse {
  final int lastModified;
  final String ignoredArticles;
  final List<Index> indexes;

  IndexesResponse({
    required this.lastModified,
    required this.ignoredArticles,
    required this.indexes,
  });

  factory IndexesResponse.fromJson(Map<String, dynamic> json) {
    return IndexesResponse(
      lastModified: json['lastModified'],
      ignoredArticles: json['ignoredArticles'],
      indexes: (json['index'] as List?)
              ?.map((index) => Index.fromJson(index))
              .toList() ??
          [],
    );
  }
}

class Index {
  final String name;
  final List<Artist> artists;

  Index({required this.name, required this.artists});

  factory Index.fromJson(Map<String, dynamic> json) {
    return Index(
      name: json['name'],
      artists: (json['artist'] as List?)
              ?.map((artist) => Artist.fromJson(artist))
              .toList() ??
          [],
    );
  }
}

class Artist {
  final String id;
  final String name;
  final String? artistImageUrl;
  final DateTime? starred;
  final int? userRating;
  final double? averageRating;

  Artist({
    required this.id,
    required this.name,
    this.artistImageUrl,
    this.starred,
    this.userRating,
    this.averageRating,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: cleanTag(json['name']),
      artistImageUrl: json['artistImageUrl'],
      starred: json['starred'] != null ? DateTime.parse(json['starred']) : null,
      userRating: json['userRating'],
      averageRating: json['averageRating']?.toDouble(),
    );
  }
}

class Album {
  final String id;
  final String name;
  final String? artist;
  final String? artistId;
  String? coverArt;
  final int songCount;
  final int duration;
  final int? playCount;
  final DateTime created;
  final DateTime? starred;
  final int? year;
  final String? genre;
  final List<Song> songs;

  Album({
    required this.id,
    required this.name,
    this.artist,
    this.artistId,
    this.coverArt,
    required this.songCount,
    required this.duration,
    this.playCount,
    required this.created,
    this.starred,
    this.year,
    this.genre,
    required this.songs,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: cleanTag(json['name']),
      artist: cleanTagOrNull(json['artist']),
      artistId: json['artistId'],
      coverArt: json['coverArt'],
      songCount: json['songCount'],
      duration: json['duration'],
      playCount: json['playCount'],
      created: DateTime.parse(json['created']),
      starred: json['starred'] != null ? DateTime.parse(json['starred']) : null,
      year: json['year'],
      genre: json['genre'],
      songs: (json['song'] as List?)
              ?.map((song) => Song.fromJson(song))
              .toList() ??
          [],
    );
  }
}

/// Trims a tag value and collapses the blank padding that tags often carry.
///
/// The library has titles/artists saved as `" Closing Time"`; trimming in one
/// place keeps every surface (lists, details, queue, Android Auto) consistent.
String cleanTag(Object? value) {
  if (value == null) return '';
  return value.toString().trim();
}

String? cleanTagOrNull(Object? value) {
  final cleaned = cleanTag(value);
  return cleaned.isEmpty ? null : cleaned;
}

class Song {
  final String id;
  final String? parent;
  final bool isDir;
  final String title;
  final String? album;
  final String? artist;
  final int? track;
  final int? year;
  final String? genre;
  final String? coverArt;
  final int? size;
  final String? contentType;
  final String? suffix;
  final int? duration;
  final int? bitRate;
  final String? path;

  Song({
    required this.id,
    this.parent,
    required this.isDir,
    required this.title,
    this.album,
    this.artist,
    this.track,
    this.year,
    this.genre,
    this.coverArt,
    this.size,
    this.contentType,
    this.suffix,
    this.duration,
    this.bitRate,
    this.path,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      parent: json['parent'],
      isDir: json['isDir'],
      title: cleanTag(json['title']),
      album: cleanTagOrNull(json['album']),
      artist: cleanTagOrNull(json['artist']),
      track: json['track'],
      year: json['year'],
      genre: json['genre'],
      coverArt: json['coverArt'],
      size: json['size'],
      contentType: json['contentType'],
      suffix: json['suffix'],
      duration: json['duration'],
      bitRate: json['bitRate'],
      path: json['path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent': parent,
      'isDir': isDir,
      'title': title,
      'album': album,
      'artist': artist,
      'track': track,
      'year': year,
      'genre': genre,
      'coverArt': coverArt,
      'size': size,
      'contentType': contentType,
      'suffix': suffix,
      'duration': duration,
      'bitRate': bitRate,
      'path': path,
    };
  }
}

class Directory {
  final String id;
  final String? parent;
  final String name;
  final DateTime? starred;
  final int? userRating;
  final double? averageRating;
  final List<Song> children;

  Directory({
    required this.id,
    this.parent,
    required this.name,
    this.starred,
    this.userRating,
    this.averageRating,
    required this.children,
  });

  factory Directory.fromJson(Map<String, dynamic> json) {
    return Directory(
      id: json['id'],
      parent: json['parent'],
      name: json['name'],
      starred: json['starred'] != null ? DateTime.parse(json['starred']) : null,
      userRating: json['userRating'],
      averageRating: json['averageRating']?.toDouble(),
      children: (json['child'] as List?)
              ?.map((child) => Song.fromJson(child))
              .toList() ??
          [],
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String? comment;
  final String? owner;
  final bool? public;
  final int songCount;
  final int duration;
  final DateTime created;
  final DateTime changed;
  final String? coverArt;
  final List<String> allowedUsers;

  Playlist({
    required this.id,
    required this.name,
    this.comment,
    this.owner,
    this.public,
    required this.songCount,
    required this.duration,
    required this.created,
    required this.changed,
    this.coverArt,
    required this.allowedUsers,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: cleanTag(json['name']),
      comment: json['comment'],
      owner: json['owner'],
      public: json['public'],
      songCount: json['songCount'],
      duration: json['duration'],
      created: DateTime.parse(json['created']),
      changed: DateTime.parse(json['changed']),
      coverArt: json['coverArt'],
      allowedUsers: (json['allowedUser'] as List?)
              ?.map((user) => user.toString())
              .toList() ??
          [],
    );
  }
}

class PlaylistWithSongs extends Playlist {
  final List<Song> songs;

  PlaylistWithSongs({
    required super.id,
    required super.name,
    super.comment,
    super.owner,
    super.public,
    required super.songCount,
    required super.duration,
    required super.created,
    required super.changed,
    super.coverArt,
    required super.allowedUsers,
    required this.songs,
  });

  factory PlaylistWithSongs.fromJson(Map<String, dynamic> json) {
    final playlist = Playlist.fromJson(json);
    return PlaylistWithSongs(
      id: playlist.id,
      name: playlist.name,
      comment: playlist.comment,
      owner: playlist.owner,
      public: playlist.public,
      songCount: playlist.songCount,
      duration: playlist.duration,
      created: playlist.created,
      changed: playlist.changed,
      coverArt: playlist.coverArt,
      allowedUsers: playlist.allowedUsers,
      songs: (json['entry'] as List?)
              ?.map((song) => Song.fromJson(song))
              .toList() ??
          [],
    );
  }
}

/// Represents a music genre in the Subsonic library
class Genre {
  /// The name of the genre
  final String name;

  /// Number of songs in this genre
  final int songCount;

  /// Number of albums in this genre
  final int albumCount;

  Genre({
    required this.name,
    required this.songCount,
    required this.albumCount,
  });

  /// Creates a Genre instance from a JSON map following the Subsonic API schema
  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      // The genre name comes as the value/content of the element in the API
      name: cleanTag(json['value'] ?? json['_']), // Servers use different keys
      songCount: json['songCount'] ?? 0,
      albumCount: json['albumCount'] ?? 0,
    );
  }

  @override
  String toString() =>
      'Genre(name: $name, songs: $songCount, albums: $albumCount)';

  /// Converts the genre to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'value': name,
      'songCount': songCount,
      'albumCount': albumCount,
    };
  }
}

/// Results from a Subsonic search, containing artists, albums and songs
class SearchResult {
  final List<Artist> artists;
  final List<Album> albums;
  final List<Song> songs;

  SearchResult({
    this.artists = const [],
    this.albums = const [],
    this.songs = const [],
  });

  factory SearchResult.fromJson(Map<String, dynamic> json,
      {required String parentName}) {
    final searchResult = json[parentName];

    final List<Artist> artists = [];
    if (searchResult['artist'] != null) {
      final artistList = searchResult['artist'] as List;
      artists.addAll(artistList.map((a) => Artist.fromJson(a)));
    }

    final List<Album> albums = [];
    if (searchResult['album'] != null) {
      final albumList = searchResult['album'] as List;
      albums.addAll(albumList.map((a) => Album.fromJson(a)));
    }

    final List<Song> songs = [];
    if (searchResult['song'] != null) {
      final songList = searchResult['song'] as List;
      songs.addAll(songList.map((s) => Song.fromJson(s)));
    }

    return SearchResult(
      artists: artists,
      albums: albums,
      songs: songs,
    );
  }
}

enum AlbumListType {
  random,
  newest,
  frequent,
  recent,
  starred,
  alphabeticalByName,
  alphabeticalByArtist,
  byYear,
  byGenre;

  String toValue() {
    switch (this) {
      case AlbumListType.random:
        return 'random';
      case AlbumListType.newest:
        return 'newest';
      case AlbumListType.frequent:
        return 'frequent';
      case AlbumListType.recent:
        return 'recent';
      case AlbumListType.starred:
        return 'starred';
      case AlbumListType.alphabeticalByName:
        return 'alphabeticalByName';
      case AlbumListType.alphabeticalByArtist:
        return 'alphabeticalByArtist';
      case AlbumListType.byYear:
        return 'byYear';
      case AlbumListType.byGenre:
        return 'byGenre';
    }
  }
}

/*
/// Represents an artist in the Subsonic library (ID3)
class Artist {
  final String id;
  final String name;
  final String? coverArt;
  final String? artistImageUrl;
  final int albumCount;
  final DateTime? starred;

  Artist({
    required this.id,
    required this.name,
    this.coverArt,
    this.artistImageUrl,
    required this.albumCount,
    this.starred,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      coverArt: json['coverArt'],
      artistImageUrl: json['artistImageUrl'],
      albumCount: json['albumCount'] ?? 0,
      starred: json['starred'] != null ? DateTime.parse(json['starred']) : null,
    );
  }
}

/// Represents an album in the Subsonic library (ID3)
class Album {
  final String id;
  final String name;
  final String? artist;
  final String? artistId;
  final String? coverArt;
  final int songCount;
  final int duration;
  final int? playCount;
  final DateTime created;
  final DateTime? starred;
  final int? year;
  final String? genre;

  Album({
    required this.id,
    required this.name,
    this.artist,
    this.artistId,
    this.coverArt,
    required this.songCount,
    required this.duration,
    this.playCount,
    required this.created,
    this.starred,
    this.year,
    this.genre,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      artist: json['artist'],
      artistId: json['artistId'],
      coverArt: json['coverArt'],
      songCount: json['songCount'] ?? 0,
      duration: json['duration'] ?? 0,
      playCount: json['playCount'],
      created: DateTime.parse(json['created']),
      starred: json['starred'] != null ? DateTime.parse(json['starred']) : null,
      year: json['year'],
      genre: json['genre'],
    );
  }
}
*/

/// A single line of lyrics.
///
/// [start] is the offset from the beginning of the track in milliseconds and is
/// only set when the lyrics are synced.
class LyricLine {
  final int? start;
  final String value;

  LyricLine({this.start, required this.value});

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      start: json['start'] as int?,
      value: (json['value'] as String?) ?? '',
    );
  }
}

/// Structured lyrics from OpenSubsonic `getLyricsBySongId`.
class StructuredLyrics {
  final String? displayArtist;
  final String? displayTitle;
  final String? lang;
  final bool synced;
  final List<LyricLine> lines;

  StructuredLyrics({
    this.displayArtist,
    this.displayTitle,
    this.lang,
    this.synced = false,
    required this.lines,
  });

  factory StructuredLyrics.fromJson(Map<String, dynamic> json) {
    final rawLines = json['line'] as List?;
    return StructuredLyrics(
      displayArtist: json['displayArtist'] as String?,
      displayTitle: json['displayTitle'] as String?,
      lang: json['lang'] as String?,
      synced: json['synced'] as bool? ?? false,
      lines: (rawLines ?? const [])
          .map((line) => LyricLine.fromJson(line as Map<String, dynamic>))
          .toList(),
    );
  }

  /// True when the lines carry timing information.
  bool get hasTimings => lines.any((line) => line.start != null);
}

/// Plain, untimed lyrics from `getLyrics`.
class Lyrics {
  final String? artist;
  final String? title;
  final String value;

  Lyrics({this.artist, this.title, required this.value});

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    return Lyrics(
      artist: json['artist'] as String?,
      title: json['title'] as String?,
      value: (json['value'] as String?) ?? '',
    );
  }
}
