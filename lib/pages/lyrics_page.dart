import 'dart:async';

import 'package:flutter/material.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';

/// Shows the lyrics of a track, highlighting the current line when the server
/// returns synced lyrics.
class LyricsPage extends ConsumerStatefulWidget {
  const LyricsPage({
    super.key,
    required this.songId,
    this.artist,
    this.title,
  });

  final String songId;
  final String? artist;
  final String? title;

  @override
  ConsumerState<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends ConsumerState<LyricsPage> {
  late Future<_LyricsResult> _lyrics;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  int _activeLine = -1;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _lyrics = _load();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<_LyricsResult> _load() async {
    final playerService = ref.read(playerServiceProvider);
    final client = playerService.client;

    // Prefer OpenSubsonic structured lyrics: they may be synced.
    final structured = await client.getLyricsBySongId(widget.songId);
    for (final candidate in structured) {
      if (candidate.synced && candidate.hasTimings) {
        _followPosition();
        return _LyricsResult.structured(candidate);
      }
    }
    if (structured.isNotEmpty) {
      return _LyricsResult.structured(structured.first);
    }

    // Fallback for servers without getLyricsBySongId: plain lyrics by tags.
    final plain = await client.getLyrics(
      artist: widget.artist,
      title: widget.title,
    );
    return _LyricsResult.plain(plain);
  }

  /// Tracks playback so the highlighted line follows the song.
  void _followPosition() {
    final playerService = ref.read(playerServiceProvider);
    _positionSubscription ??=
        playerService.audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      final result = _result;
      if (result == null || !result.isSynced) return;
      final index = _indexFor(position.inMilliseconds, result.lines);
      if (index != _activeLine) {
        setState(() => _activeLine = index);
        _scrollToActive(index);
      }
    });
  }

  _LyricsResult? _result;

  int _indexFor(int positionMs, List<LyricLine> lines) {
    var index = 0;
    for (var i = 0; i < lines.length; i++) {
      final start = lines[i].start;
      if (start != null && start <= positionMs) {
        index = i;
      }
    }
    return index;
  }

  void _scrollToActive(int index) {
    final key = _lineKeys[index];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      alignment: 0.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.lyrics),
            if (widget.title != null)
              Text(
                widget.title!,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: FutureBuilder<_LyricsResult>(
        future: _lyrics,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _Message(text: context.l10n.lyricsError('${snapshot.error}'));
          }
          final result = snapshot.data;
          _result = result;
          if (result == null || result.isEmpty) {
            return _Message(text: context.l10n.lyricsEmpty);
          }

          final lines = result.lines;
          _lineKeys.clear();
          for (var i = 0; i < lines.length; i++) {
            _lineKeys[i] = GlobalKey();
          }

          final theme = Theme.of(context);
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final isActive = result.isSynced && index == _activeLine;
              final text = lines[index].value;
              return Padding(
                key: _lineKeys[index],
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  text.isEmpty ? ' ' : text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lyrics_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LyricsResult {
  final List<LyricLine> lines;
  final bool isSynced;

  const _LyricsResult._(this.lines, this.isSynced);

  factory _LyricsResult.structured(StructuredLyrics lyrics) {
    return _LyricsResult._(
      lyrics.lines.where((line) => line.value.trim().isNotEmpty).toList(),
      lyrics.synced && lyrics.hasTimings,
    );
  }

  factory _LyricsResult.plain(Lyrics? lyrics) {
    if (lyrics == null) return const _LyricsResult._([], false);
    return _LyricsResult._(
      [
        for (final line in lyrics.value.split('\n'))
          LyricLine(value: line.trimRight()),
      ],
      false,
    );
  }

  bool get isEmpty => lines.isEmpty;
}
