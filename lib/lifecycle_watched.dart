import 'package:flutter/material.dart';
import 'package:inject_x/inject_x.dart';
import 'package:random_mu/services/player_service.dart';
import 'package:random_mu/services/update_checker.dart';

class LifecycleWatcher extends StatefulWidget {
  final Widget child;

  const LifecycleWatcher({super.key, required this.child});

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Schedule checkForUpdates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdates(context);
      _resumePlaying();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Schedule checkForUpdates when app resumes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkForUpdates(context);
        _resumePlaying();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> _resumePlaying() async {
    final playerService = inject<PlayerService>();
    await playerService.restoreSongs();
  }
}
