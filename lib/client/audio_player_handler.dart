import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_mu/services/player_service.dart';

class AudioPlayerHandler extends BaseAudioHandler
    with
        QueueHandler, // mix in default queue callback implementations
        SeekHandler {
  // {
  final PlayerService playerService;
  static const platform = MethodChannel('com.babisoft.randommu/android_auto');

  AudioPlayerHandler(this.playerService) {
    _setupMethodCallHandler();
    _setupPlayerListeners();
  }

  void _setupMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'playMedia':
          await playerService.play();
          return true;
        case 'pauseMedia':
          await playerService.pause();
          return true;
        case 'skipToNext':
          await playerService.next();
          return true;
        case 'skipToPrevious':
          await playerService.previous();
          return true;
        case 'seekTo':
          final position = Duration(milliseconds: call.arguments as int);
          await playerService.audioPlayer.seek(position);
          return true;
        default:
          throw PlatformException(
            code: 'UNSUPPORTED_METHOD',
            message: 'Method ${call.method} not supported',
          );
      }
    });
  }

  void _setupPlayerListeners() {
    playerService.audioPlayer.playerStateStream.listen((state) {
      _updatePlaybackState(state);
    });

    playerService.audioPlayer.positionStream.listen((position) {
      _updatePlaybackPosition(position);
    });
  }

  Future<void> _updatePlaybackState(PlayerState state) async {
    final isPlaying = state.playing;
    await platform.invokeMethod('updatePlaybackState', {
      'isPlaying': isPlaying,
      'playbackState': isPlaying ? 'playing' : 'paused',
    });
  }

  Future<void> _updatePlaybackPosition(Duration position) async {
    await platform.invokeMethod('updatePlaybackPosition', {
      'position': position.inMilliseconds,
    });
  }

  Future<void> updateMediaMetadata({
    required String title,
    required String artist,
    required String album,
    String? artworkUri,
    Duration? duration,
  }) async {
    await platform.invokeMethod('updateMediaMetadata', {
      'title': title,
      'artist': artist,
      'album': album,
      'artworkUri': artworkUri,
      'duration': duration?.inMilliseconds,
    });
  }

  // The most common callbacks:
  @override
  Future<void> play() => playerService.audioPlayer.play();
  @override
  Future<void> pause() => playerService.pause();
  @override
  Future<void> stop() => playerService.pause();
  @override
  Future<void> seek(Duration position) =>
      playerService.audioPlayer.seek(position);
  @override
  Future<void> skipToQueueItem(int index) =>
      playerService.audioPlayer.seek(Duration.zero, index: index);

  @override
  Future<void> skipToNext() => playerService.previous();

  @override
  Future<void> skipToPrevious() => playerService.next();
}
