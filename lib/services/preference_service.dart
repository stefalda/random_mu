import 'dart:convert';

import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/services/playback_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _playbackModeKey = 'playback_mode';

  Future<void> storePlaybackMode(PlaybackMode mode) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_playbackModeKey, mode.storageValue);
  }

  /// The last used playback mode; [PlaybackMode.sequenziale] on a fresh install.
  Future<PlaybackMode> retrievePlaybackMode() async {
    final pref = await SharedPreferences.getInstance();
    return PlaybackMode.fromStorage(pref.getString(_playbackModeKey));
  }
  Future<void> storeLatestPlaylist(List<Song> songs) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setStringList(
        "songs", songs.map((song) => jsonEncode(song)).toList());
  }

  Future<List<Song>?> retrieveLatestPlaylist() async {
    final pref = await SharedPreferences.getInstance();
    final List<String>? list = pref.getStringList("songs");
    if (list == null) return null;
    return list
        .map((songString) => Song.fromJson(jsonDecode(songString)))
        .toList();
  }

  Future<void> storeCurrentPlayingSong(int index) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setInt("songIndex", index);
  }

  Future<int> retrieveCurrentPlayingSongIndex() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getInt("songIndex") ?? 0;
  }
}
