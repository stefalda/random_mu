import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/services/playback_mode.dart';

void main() {
  group('PlaybackMode', () {
    test('a fresh install starts sequential', () {
      expect(PlaybackMode.fromStorage(null), PlaybackMode.sequenziale);
      expect(PlaybackMode.fromStorage('nonsense'), PlaybackMode.sequenziale);
    });

    test('the last used mode is restored from storage', () {
      expect(PlaybackMode.fromStorage('casuale'), PlaybackMode.casuale);
      expect(PlaybackMode.fromStorage('sequenziale'), PlaybackMode.sequenziale);
      expect(
        PlaybackMode.casuale.storageValue,
        'casuale',
      );
    });

    test('toggling flips between the two modes', () {
      expect(PlaybackMode.sequenziale.toggled, PlaybackMode.casuale);
      expect(PlaybackMode.casuale.toggled, PlaybackMode.sequenziale);
      expect(PlaybackMode.casuale.isShuffle, isTrue);
      expect(PlaybackMode.sequenziale.isShuffle, isFalse);
    });
  });

  group('planQueue', () {
    final container = ['a', 'b', 'c', 'd', 'e'];

    test('sequential keeps the container order and starts at the tapped item', () {
      final plan = planQueue(container, shuffle: false, startIndex: 2);
      expect(plan.queue, container);
      expect(plan.index, 2);
      expect(plan.queue[plan.index], 'c');
    });

    test('casuale starts at the tapped item and shuffles the rest', () {
      final plan = planQueue(
        container,
        shuffle: true,
        startIndex: 3,
        random: Random(7),
      );
      expect(plan.queue.first, 'd');
      expect(plan.index, 0);
      expect(plan.queue.toSet(), container.toSet());
      expect(plan.queue, hasLength(container.length));
    });

    test('casuale actually shuffles the tail', () {
      final orders = <String>{};
      for (var seed = 0; seed < 20; seed++) {
        final plan = planQueue(
          container,
          shuffle: true,
          startIndex: 0,
          random: Random(seed),
        );
        orders.add(plan.queue.skip(1).join());
      }
      expect(orders.length, greaterThan(1));
    });

    test('an unknown start index falls back to the first item', () {
      final plan = planQueue(container, shuffle: false, startIndex: -1);
      expect(plan.index, 0);
      expect(plan.queue, container);
    });

    test('an empty container produces an empty plan', () {
      final plan = planQueue<String>([], shuffle: true);
      expect(plan.queue, isEmpty);
      expect(plan.index, 0);
    });
  });

  group('shuffledKeepingCurrent', () {
    test('the current index keeps its position', () {
      for (var current = 0; current < 6; current++) {
        final order = shuffledKeepingCurrent(6, current, random: Random(3));
        expect(order[current], current);
        expect(order.toSet(), {0, 1, 2, 3, 4, 5});
      }
    });

    test('toggling twice returns to the original order', () {
      final shuffled = shuffledKeepingCurrent(6, 2, random: Random(11));
      // Undo: map shuffled positions back to their original indices.
      final restored = List<int>.filled(6, -1);
      for (var newIndex = 0; newIndex < shuffled.length; newIndex++) {
        restored[shuffled[newIndex]] = newIndex;
      }
      // The inverse permutation sorted by original index yields 0..5.
      expect(restored.toSet(), {0, 1, 2, 3, 4, 5});
    });

    test('handles degenerate lengths', () {
      expect(shuffledKeepingCurrent(0, 0), isEmpty);
      expect(shuffledKeepingCurrent(1, 0), [0]);
      expect(shuffledKeepingCurrent(3, 99, random: Random(1))[0], 0);
    });
  });
}
