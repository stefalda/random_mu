import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/providers/paged_albums_notifier.dart';

void main() {
  group('appendUnique', () {
    test('appends new items keeping the order', () {
      final merged = appendUnique([1, 2], [3, 4], (item) => item);
      expect(merged, [1, 2, 3, 4]);
    });

    test('drops duplicates, so a repeated page cannot loop forever', () {
      // A server that ignores the offset would keep answering the same page.
      final merged = appendUnique([1, 2, 3], [1, 2, 3], (item) => item);
      expect(merged, [1, 2, 3]);
      expect(merged.length, 3);
    });

    test('respects the key function', () {
      final merged = appendUnique(
        [{'id': 'a'}],
        [
          {'id': 'a'},
          {'id': 'b'},
        ],
        (item) => item['id']!,
      );
      expect(merged.map((item) => item['id']), ['a', 'b']);
    });
  });

  group('PagedList', () {
    test('starts empty and continues by default', () {
      const page = PagedList<int>();
      expect(page.items, isEmpty);
      expect(page.hasMore, isTrue);
      expect(page.loadingMore, isFalse);
      expect(page.filter, isEmpty);
    });

    test('copyWith keeps untouched fields', () {
      const page = PagedList<int>(items: [1, 2], hasMore: false, filter: 'x');
      final next = page.copyWith(loadingMore: true);
      expect(next.items, [1, 2]);
      expect(next.hasMore, isFalse);
      expect(next.filter, 'x');
      expect(next.loadingMore, isTrue);
    });
  });
}
