import 'package:bdsm_tree/bdsm_tree.dart';
import 'package:test/test.dart';

void main() {
  group('BDSMTree with integer keys and string values', () {
    late BDSMTree<int, String> tree;

    setUp(() {
      // Create a tree sorted by values
      tree =
          BDSMTree<int, String>.withValueComparator((a, b) => a.compareTo(b));
    });

    test('initial state', () {
      expect(tree.isEmpty, isTrue);
      expect(tree.isNotEmpty, isFalse);
      expect(tree.length, equals(0));
      expect(tree.firstKey(), isNull);
      expect(tree.lastKey(), isNull);
    });

    test('add and retrieve values', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');

      expect(tree.isEmpty, isFalse);
      expect(tree.isNotEmpty, isTrue);
      expect(tree.length, equals(3));
      expect(tree.get(1), equals('apple'));
      expect(tree.get(2), equals('banana'));
      expect(tree.get(3), equals('cherry'));
      expect(tree.get(4), isNull);
    });

    test('values are sorted correctly', () {
      // Adding in unsorted order
      tree.add(3, 'cherry');
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      // Values should be returned in sorted order
      expect(tree.toList(), equals(['apple', 'banana', 'cherry']));
      expect(tree.firstKey(), equals(1)); // key for 'apple'
      expect(tree.lastKey(), equals(3)); // key for 'cherry'
    });

    test('putIfAbsent', () {
      tree.add(1, 'apple');

      // This should use the existing value
      var value = tree.putIfAbsent(1, () => 'orange');
      expect(value, equals('apple'));
      expect(tree.get(1), equals('apple'));

      // This should add a new value
      value = tree.putIfAbsent(2, () => 'banana');
      expect(value, equals('banana'));
      expect(tree.get(2), equals('banana'));
    });

    test('update', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      var value = tree.update(1, (v) => 'updated $v');
      expect(value, equals('updated apple'));
      expect(tree.get(1), equals('updated apple'));

      // Test with ifAbsent
      value = tree.update(3, (v) => v, ifAbsent: () => 'cherry');
      expect(value, equals('cherry'));
      expect(tree.get(3), equals('cherry'));

      // Test throws error when key not found and no ifAbsent
      expect(() => tree.update(4, (v) => v), throwsArgumentError);
    });

    test('updateAll', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      tree.updateAll((key, value) => '$key# $value');

      expect(tree.get(1), equals('1# apple'));
      expect(tree.get(2), equals('2# banana'));
    });

    test('addAll', () {
      final map = {1: 'apple', 2: 'banana', 3: 'cherry'};
      tree.addAll(map);

      expect(tree.length, equals(3));
      expect(tree.toList(), equals(['apple', 'banana', 'cherry']));
    });

    test('removeKey', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');

      expect(tree.removeKey(2), isTrue);
      expect(tree.length, equals(2));
      expect(tree.toList(), equals(['apple', 'cherry']));
      expect(tree.removeKey(4), isFalse); // Non-existent key
    });

    test('removeValue', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');

      expect(tree.removeValue('banana'), isTrue);
      expect(tree.length, equals(2));
      expect(tree.toList(), equals(['apple', 'cherry']));
      expect(tree.removeValue('grape'), isFalse); // Non-existent value
    });

    test('removeAll', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');

      final removed = tree.removeAll(['banana', 'orange']);
      expect(
          removed, equals(['banana'])); // Only 'banana' was found and removed
      expect(tree.length, equals(2));
      expect(tree.toList(), equals(['apple', 'cherry']));
    });

    test('removeWhere', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');

      final removed = tree.removeWhere((value) => value.startsWith('b'));
      expect(removed, equals(['banana']));
      expect(tree.length, equals(2));
      expect(tree.toList(), equals(['apple', 'cherry']));
    });

    test('getKey', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      expect(tree.getKey('apple'), equals(1));
      expect(tree.getKey('banana'), equals(2));
      expect(tree.getKey('orange'), isNull); // Non-existent value
    });

    test('containsKey and containsValue', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      expect(tree.containsKey(1), isTrue);
      expect(tree.containsKey(3), isFalse);

      expect(tree.containsValue('apple'), isTrue);
      expect(tree.containsValue('orange'), isFalse);
    });

    test('clear', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      tree.clear();
      expect(tree.isEmpty, isTrue);
      expect(tree.length, equals(0));
    });

    test('forEach', () {
      tree.add(3, 'cherry');
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      final values = <String>[];
      tree.forEach((value) {
        values.add(value);
      });

      expect(values, equals(['apple', 'banana', 'cherry']));
    });

    test('forEachEntry', () {
      tree.add(3, 'cherry');
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      final entries = <String>[];
      tree.forEachEntry((key, value) {
        entries.add('$key: $value');
      });

      expect(entries, equals(['1: apple', '2: banana', '3: cherry']));
    });

    test('lastKeyBefore and firstKeyAfter', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');
      tree.add(4, 'date');

      expect(
          tree.lastKeyBefore(2), equals(1)); // Key before 'banana' is 'apple'
      expect(
          tree.firstKeyAfter(2), equals(3)); // Key after 'banana' is 'cherry'

      expect(tree.lastKeyBefore(1), isNull); // No key before the first
      expect(tree.firstKeyAfter(4), isNull); // No key after the last
    });

    test('lastValueBefore and firstValueAfter', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');
      tree.add(4, 'date');

      expect(tree.lastValueBefore(2),
          equals('apple')); // Value before 'banana' is 'apple'
      expect(tree.firstValueAfter(2),
          equals('cherry')); // Value after 'banana' is 'cherry'

      expect(tree.lastValueBefore(1), isNull); // No value before the first
      expect(tree.firstValueAfter(4), isNull); // No value after the last
    });

    test('rebalanceAll', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');

      // This is hard to test directly, but we can ensure it doesn't break anything
      tree.rebalanceAll();

      expect(tree.length, equals(3));
      expect(tree.toList(), equals(['apple', 'banana', 'cherry']));
    });

    test('rebalanceWhere', () {
      tree.add(1, 'apple');
      tree.add(2, 'banana');
      tree.add(3, 'cherry');

      // This is hard to test directly, but we can ensure it doesn't break anything
      tree.rebalanceWhere((value) => value.startsWith('b'));

      expect(tree.length, equals(3));
      expect(tree.toList(), equals(['apple', 'banana', 'cherry']));
    });

    test('iteration', () {
      tree.add(3, 'cherry');
      tree.add(1, 'apple');
      tree.add(2, 'banana');

      final values = <String>[];
      for (final value in tree) {
        values.add(value);
      }

      expect(values, equals(['apple', 'banana', 'cherry']));
    });
  });
}
