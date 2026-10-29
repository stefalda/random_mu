import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent cache of the Android Auto browse tree.
///
/// `audio_service` 0.18 does not serialize [MediaItem], so the fields used by the
/// browse tree are mapped explicitly. Each browse node is stored under its own
/// preference key, keeping writes small and deletions cheap.
class BrowseCache {
  static const String _nodeKeyPrefix = 'aa_browse_node_';

  const BrowseCache();

  String _key(String nodeId) => '$_nodeKeyPrefix$nodeId';

  /// Returns the cached children of [parentId], or null when nothing is cached.
  Future<List<MediaItem>?> loadNode(String parentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(parentId));
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((entry) => _itemFromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Replaces the cached children of [parentId].
  Future<void> saveNode(String parentId, List<MediaItem> children) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(parentId),
      jsonEncode(children.map(_itemToJson).toList()),
    );
  }

  /// Drops a browse node (e.g. the container of a deleted download).
  Future<void> removeNode(String nodeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(nodeId));
  }

  /// Inserts or replaces [node] inside the cached [categoryId] node.
  Future<void> upsertInCategory(String categoryId, MediaItem node) async {
    final children = await loadNode(categoryId) ?? <MediaItem>[];
    final updated = [
      for (final child in children)
        if (child.id != node.id) child,
      node,
    ];
    await saveNode(categoryId, updated);
  }

  /// Removes [nodeId] from the cached [categoryId] node.
  Future<void> removeFromCategory(String categoryId, String nodeId) async {
    final children = await loadNode(categoryId);
    if (children == null) return;
    await saveNode(
      categoryId,
      children.where((child) => child.id != nodeId).toList(),
    );
  }

  /// Drops every cached browse node.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_nodeKeyPrefix));
    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
  }

  Map<String, dynamic> _itemToJson(MediaItem item) => {
        'id': item.id,
        'title': item.title,
        if (item.album != null) 'album': item.album,
        if (item.artist != null) 'artist': item.artist,
        if (item.duration != null) 'duration': item.duration!.inMilliseconds,
        if (item.artUri != null) 'artUri': item.artUri.toString(),
        if (item.playable != null) 'playable': item.playable,
        if (item.extras != null) 'extras': item.extras,
      };

  MediaItem _itemFromJson(Map<String, dynamic> json) {
    final duration = json['duration'] as int?;
    final artUri = json['artUri'] as String?;
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      album: json['album'] as String?,
      artist: json['artist'] as String?,
      duration: duration != null ? Duration(milliseconds: duration) : null,
      artUri: artUri != null ? Uri.parse(artUri) : null,
      playable: json['playable'] as bool?,
      extras: (json['extras'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
