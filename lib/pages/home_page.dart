import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/pages/connection/connection_page.dart';
import 'package:random_mu/pages/library/library_shell.dart';
import 'package:random_mu/providers/subsonic_preferences_provider.dart';

class HomePage extends ConsumerWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionDetails = ref.watch(connectionDetailsProvider);
    bool shouldLogin = !connectionDetails.isCompiled();
    return Scaffold(
      /* appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),*/
      body: SafeArea(
          child: shouldLogin ? const Center(child: ConnectionPage()) : const LibraryShell()),

      /* floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final playerService = ref.read(playerServiceProvider);
          await playerService.randomAll();
          await playerService.play();
        },
        tooltip: 'Randomize',
        child: const Icon(
          Icons.refresh,
          size: 40,
        ),
      ), */ // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
