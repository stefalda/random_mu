import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:random_mu/pages/home_page.dart';
import 'package:random_mu/providers/albums_notifier.dart';
import 'package:random_mu/providers/artists_notifier.dart';
import 'package:random_mu/providers/albums_state.dart';
import 'package:random_mu/providers/artists_state.dart';
import 'package:random_mu/providers/loading_notifier.dart';
import 'package:random_mu/providers/playlists_notifier.dart';
import 'package:random_mu/providers/playlists_state.dart';
import 'package:random_mu/providers/subsonic_preferences_provider.dart';
import 'package:random_mu/services/player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Providers
final playerServiceProvider = Provider<PlayerService>((ref) {
  final connectionDetails = ref.watch(connectionDetailsProvider);
  return PlayerService(
      serverUrl: connectionDetails.serverUrl,
      username: connectionDetails.username,
      password: connectionDetails.password);
});

// Provider for the player's state stream
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final audioPlayer = ref.watch(playerServiceProvider).audioPlayer;
  return audioPlayer.playerStateStream;
});

// Artists
final artistsProvider =
    AsyncNotifierProvider<ArtistsNotifier, ArtistsState>(() {
  return ArtistsNotifier();
});

// Albums
final albumsProvider = AsyncNotifierProvider<AlbumsNotifier, AlbumsState>(() {
  return AlbumsNotifier();
});

// Playlists
final playlistsProvider =
    AsyncNotifierProvider<PlaylistsNotifier, PlaylistsState>(() {
  return PlaylistsNotifier();
});

// Create a search controller provider
final searchControllerProvider = Provider.autoDispose((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// Loading provider
final loadingProvider =
    StateNotifierProvider<LoadingNotifier, bool>((ref) => LoadingNotifier());

// Provider to handle the SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this provider in your main.dart');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Initialize background audio integration
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(ProviderScope(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RandomMusic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.indigo, // Customize primary color
        scaffoldBackgroundColor: Colors.black, // Background color
        textTheme: ThemeData.dark().textTheme.copyWith(
              titleLarge: TextStyle(color: Colors.white, fontSize: 20),
              titleSmall: TextStyle(color: Colors.grey[300]),
            ),
        appBarTheme: AppBarTheme(
          //color: Theme.of(context).colorScheme.inversePrimary,
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        cardColor: Colors.grey[850], // Card background
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.teal, // Button color
          textTheme: ButtonTextTheme.primary,
        ),
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomePage(title: 'RandomMusic'),
    );
  }
}
