import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';

class LoadingIndicator extends ConsumerStatefulWidget {
  const LoadingIndicator({super.key});

  @override
  ConsumerState<LoadingIndicator> createState() => LoadingState();
}

class LoadingState extends ConsumerState<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Create the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    // Dispose the controller when no longer needed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(loadingProvider);
    debugPrint("Loading $loading");
    if (loading) {
      _controller.repeat();
    } else {
      _controller.stop();
      return SizedBox(width: 32,);
    }

    return SizedBox(
        width: 32,
        child: Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: RotationTransition(
          turns: _controller,
          child: const Icon(Icons.sync, color: Colors.white)),
    ));
  }
}
