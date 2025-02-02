import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/queue/queue_list.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          title: Header(title: "Queue"),
          actions: [
            SizedBox(
              width: 32,
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: QueueList(),
        ));
  }
}
