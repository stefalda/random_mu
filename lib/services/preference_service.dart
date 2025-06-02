import 'dart:convert';

import 'package:random_mu/client/subsonic_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
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
