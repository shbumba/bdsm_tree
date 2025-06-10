import 'package:bdsm_tree/bdsm_tree.dart';
import 'package:test/test.dart';

void main() {
  group('BDSMTree comparator change tests', () {
    late BDSMTree<String, int> tree;

    setUp(() {
      // Initial comparator: ascending order by values
      tree = BDSMTree<String, int>(
          (pair1, pair2) => pair1.value.compareTo(pair2.value));

      // Add test data
      tree.add('a', 10);
      tree.add('b', 30);
      tree.add('c', 20);
    });

    test('initial order with ascending comparator', () {
      // With ascending comparator, values should be sorted as: 10, 20, 30
      expect(tree.toList(), equals([10, 20, 30]));
      expect(tree.firstKey(), equals('a')); // Key for value 10
      expect(tree.lastKey(), equals('b')); // Key for value 30
    });

    test('changing comparator to descending rebalances tree', () {
      // Change to descending order
      tree.setComparator((pair1, pair2) => pair2.value.compareTo(pair1.value));

      // Order should now be reversed: 30, 20, 10
      expect(tree.toList(), equals([30, 20, 10]));
      expect(tree.firstKey(), equals('b')); // Key for value 30
      expect(tree.lastKey(), equals('a')); // Key for value 10
    });

    test('changing comparator affects bi-directional navigation', () {
      // Initial state - ascending
      expect(tree.lastValueBefore('c'),
          equals(10)); // Value before 'c' (20) is 'a' (10)
      expect(tree.firstValueAfter('c'),
          equals(30)); // Value after 'c' (20) is 'b' (30)

      // Change to descending
      tree.setComparator((pair1, pair2) => pair2.value.compareTo(pair1.value));

      // Relationships are now reversed
      expect(tree.lastValueBefore('c'),
          equals(30)); // Value before 'c' (20) is 'b' (30)
      expect(tree.firstValueAfter('c'),
          equals(10)); // Value after 'c' (20) is 'a' (10)
    });

    test('changing comparator to equivalent function rebuilds tree', () {
      // This is functionally equivalent to the original but a new instance
      final newComparatorSameOrder =
          (Pair<String, int> a, Pair<String, int> b) =>
              a.value.compareTo(b.value);

      // Changing should trigger rebalance but order stays the same
      tree.setComparator(newComparatorSameOrder);

      // Order should remain the same
      expect(tree.toList(), equals([10, 20, 30]));
    });

    test('changing comparator on empty tree does not fail', () {
      final emptyTree =
          BDSMTree<String, int>((a, b) => a.value.compareTo(b.value));

      // Changing comparator on empty tree should not throw
      expect(
          () => emptyTree.setComparator((a, b) => b.value.compareTo(a.value)),
          returnsNormally);
    });

    test('comparator change with complex sorting criteria', () {
      // Create a tree with multi-criteria sorting
      final complexTree = BDSMTree<String, List<int>>((a, b) {
        // Sort by first element
        return a.value[0].compareTo(b.value[0]);
      });

      // Add elements
      complexTree.add('a', [1, 10]);
      complexTree.add('b', [2, 5]);
      complexTree.add('c', [3, 8]);

      // Initial order by first element: [1,10], [2,5], [3,8]
      expect(
          complexTree.toList(),
          equals([
            [1, 10],
            [2, 5],
            [3, 8]
          ]));

      // Change to sort by second element
      complexTree.setComparator((a, b) => a.value[1].compareTo(b.value[1]));

      // New order should be: [2,5], [3,8], [1,10]
      expect(
          complexTree.toList(),
          equals([
            [2, 5],
            [3, 8],
            [1, 10]
          ]));
    });

    test('adding elements after comparator change uses new order', () {
      // Change to descending order
      tree.setComparator((pair1, pair2) => pair2.value.compareTo(pair1.value));

      // Add a new element
      tree.add('d', 15);

      // Should be inserted according to new descending order: 30, 20, 15, 10
      expect(tree.toList(), equals([30, 20, 15, 10]));
    });
  });

  group('BDSMTree multiple comparator changes', () {
    test('multiple changes with operations between them', () {
      final tree = BDSMTree<String, int>(
          (pair1, pair2) => pair1.value.compareTo(pair2.value));

      // Add elements with ascending sort
      tree.add('a', 10);
      tree.add('b', 30);
      tree.add('c', 20);

      expect(tree.toList(), equals([10, 20, 30]));

      // Change to descending
      tree.setComparator((pair1, pair2) => pair2.value.compareTo(pair1.value));
      expect(tree.toList(), equals([30, 20, 10]));

      // Add more elements
      tree.add('d', 25);
      tree.add('e', 15);

      // Should follow descending order
      expect(tree.toList(), equals([30, 25, 20, 15, 10]));

      // Change back to ascending
      tree.setComparator((pair1, pair2) => pair1.value.compareTo(pair2.value));
      expect(tree.toList(), equals([10, 15, 20, 25, 30]));

      // Remove an element
      tree.removeKey('c'); // removing 20
      expect(tree.toList(), equals([10, 15, 25, 30]));

      // Change to custom order (odd numbers first, then even, each group ascending)
      tree.setComparator((pair1, pair2) {
        final isOdd1 = pair1.value % 2 == 1;
        final isOdd2 = pair2.value % 2 == 1;

        if (isOdd1 && !isOdd2) return -1;
        if (!isOdd1 && isOdd2) return 1;
        return pair1.value.compareTo(pair2.value);
      });

      // Should now be [15, 25, 10, 30] (odds first, then evens)
      expect(tree.toList(), equals([15, 25, 10, 30]));
    });
  });
}
