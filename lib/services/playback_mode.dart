import 'dart:math';

/// How a container (album, playlist, artist, favorites, genre) becomes a queue.
enum PlaybackMode {
  /// Keep the container order and start at the selected track.
  sequenziale,

  /// Start at the selected track and shuffle the rest.
  casuale;

  static const String _storedSequenziale = 'sequenziale';
  static const String _storedCasuale = 'casuale';

  /// Value used by the preference store.
  String get storageValue =>
      this == PlaybackMode.casuale ? _storedCasuale : _storedSequenziale;

  String get label => this == PlaybackMode.casuale ? 'Casuale' : 'Sequenziale';

  bool get isShuffle => this == PlaybackMode.casuale;

  /// The last used mode is restored from storage; a fresh install starts
  /// sequential.
  static PlaybackMode fromStorage(String? value) {
    return value == _storedCasuale
        ? PlaybackMode.casuale
        : PlaybackMode.sequenziale;
  }

  PlaybackMode get toggled =>
      this == PlaybackMode.casuale
          ? PlaybackMode.sequenziale
          : PlaybackMode.casuale;
}

/// A queue to hand to the player: the items in listening order plus the index
/// that must start playing.
class PlaybackPlan<T> {
  const PlaybackPlan(this.queue, this.index);

  final List<T> queue;
  final int index;
}

/// Builds the listening order for [container] starting at [startIndex].
///
/// Sequential keeps the container order; casuale puts the selected item first
/// and shuffles the rest. [random] is injectable for tests.
PlaybackPlan<T> planQueue<T>(
  List<T> container, {
  required bool shuffle,
  int startIndex = 0,
  Random? random,
}) {
  if (container.isEmpty) return PlaybackPlan<T>(const [], 0);
  final index =
      startIndex >= 0 && startIndex < container.length ? startIndex : 0;
  if (!shuffle) {
    return PlaybackPlan<T>(List<T>.of(container), index);
  }

  final rest = <T>[
    for (var i = 0; i < container.length; i++)
      if (i != index) container[i],
  ];
  _shuffle(rest, random);
  return PlaybackPlan<T>([container[index], ...rest], 0);
}

/// Returns the new order of the current indices when shuffling a live queue:
/// the item at [currentIndex] keeps its position, everything else is shuffled.
List<int> shuffledKeepingCurrent(
  int length,
  int currentIndex, {
  Random? random,
}) {
  if (length <= 0) return const [];
  final current =
      currentIndex >= 0 && currentIndex < length ? currentIndex : 0;
  final others = <int>[
    for (var i = 0; i < length; i++)
      if (i != current) i,
  ];
  _shuffle(others, random);
  return [...others]..insert(current, current);
}

void _shuffle<T>(List<T> items, Random? random) {
  if (random == null) {
    items.shuffle();
  } else {
    items.shuffle(random);
  }
}
