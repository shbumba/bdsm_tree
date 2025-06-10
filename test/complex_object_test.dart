import 'package:bdsm_tree/bdsm_tree.dart';
import 'package:test/test.dart';

/// A simple test class with a comparable value property
class TestObject {
  final String id;
  final int value;
  
  const TestObject(this.id, this.value);
  
  @override
  String toString() => 'TestObject(id: $id, value: $value)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestObject && other.id == id && other.value == value;
  }
  
  @override
  int get hashCode => Object.hash(id, value);
}

void main() {
  group('BDSMTree with string keys and complex objects', () {
    late BDSMTree<String, TestObject> tree;
    
    setUp(() {
      // Create a tree that sorts based on the TestObject.value property
      tree = BDSMTree<String, TestObject>((pair1, pair2) {
        return pair1.value.value.compareTo(pair2.value.value);
      });
    });
    
    test('initial state', () {
      expect(tree.isEmpty, isTrue);
      expect(tree.length, equals(0));
    });
    
    test('add and retrieve values sorted by object.value', () {
      // Add objects with values in unsorted order
      tree.add('c', TestObject('obj3', 30));
      tree.add('a', TestObject('obj1', 10));
      tree.add('b', TestObject('obj2', 20));
      
      // Expect values to be retrieved in order of their numeric value
      final values = tree.toList();
      expect(values[0].value, equals(10));
      expect(values[1].value, equals(20));
      expect(values[2].value, equals(30));
      
      // The keys should match the objects
      expect(tree.get('a')?.value, equals(10));
      expect(tree.get('b')?.value, equals(20));
      expect(tree.get('c')?.value, equals(30));
    });
    
    test('update value affects sorting', () {
      tree.add('a', TestObject('obj1', 10));
      tree.add('b', TestObject('obj2', 20));
      tree.add('c', TestObject('obj3', 30));
      
      // Initial order: a, b, c (10, 20, 30)
      expect(tree.toList().map((obj) => obj.value), equals([10, 20, 30]));
      
      // Update b to have the largest value
      tree.update('b', (obj) => TestObject(obj.id, 40));
      
      // New order should be a, c, b (10, 30, 40)
      final newValues = tree.toList().map((obj) => obj.value).toList();
      expect(newValues, equals([10, 30, 40]));
      
      // Keys still map to correct objects
      expect(tree.get('a')?.value, equals(10));
      expect(tree.get('b')?.value, equals(40));
      expect(tree.get('c')?.value, equals(30));
    });
    
    test('bi-directional navigation with lastValueBefore and firstValueAfter', () {
      tree.add('a', TestObject('obj1', 10));
      tree.add('b', TestObject('obj2', 20));
      tree.add('c', TestObject('obj3', 30));
      tree.add('d', TestObject('obj4', 40));
      
      // Find the value before/after by key
      final beforeB = tree.lastValueBefore('b');
      final afterB = tree.firstValueAfter('b');
      
      expect(beforeB?.value, equals(10)); // Value before b is a's object
      expect(afterB?.value, equals(30));  // Value after b is c's object
      
      // Check boundary conditions
      expect(tree.lastValueBefore('a'), isNull); // Nothing before the first
      expect(tree.firstValueAfter('d'), isNull); // Nothing after the last
    });
    
    test('removeWhere based on object property', () {
      tree.add('a', TestObject('obj1', 10));
      tree.add('b', TestObject('obj2', 20));
      tree.add('c', TestObject('obj3', 30));
      tree.add('d', TestObject('obj4', 40));
      
      // Remove all objects with value > 25
      final removed = tree.removeWhere((obj) => obj.value > 25);
      
      expect(removed.map((obj) => obj.value).toList(), equals([30, 40]));
      expect(tree.length, equals(2));
      expect(tree.toList().map((obj) => obj.value).toList(), equals([10, 20]));
    });
    
    test('iterator returns objects in sorted order', () {
      tree.add('c', TestObject('obj3', 30));
      tree.add('a', TestObject('obj1', 10));
      tree.add('b', TestObject('obj2', 20));
      
      final values = <int>[];
      for (final obj in tree) {
        values.add(obj.value);
      }
      
      expect(values, equals([10, 20, 30]));
    });
    
    test('getKey returns the key for a matching object', () {
      tree.add('a', TestObject('obj1', 10));
      tree.add('b', TestObject('obj2', 20));
      
      // Equal object with same properties
      final key = tree.getKey(TestObject('obj2', 20));
      expect(key, equals('b'));
      
      // Equal ID but different value
      final notFound = tree.getKey(TestObject('obj2', 25));
      expect(notFound, isNull);
    });
    
    test('rebalance maintains correct order', () {
      tree.add('c', TestObject('obj3', 30));
      tree.add('a', TestObject('obj1', 10));
      tree.add('b', TestObject('obj2', 20));
      
      tree.rebalanceAll();
      
      final values = <int>[];
      tree.forEach((obj) {
        values.add(obj.value);
      });
      
      expect(values, equals([10, 20, 30]));
    });
    
    test('handle duplicate values', () {
      // Objects with same value but different IDs
      tree.add('a', TestObject('obj1', 10));
      tree.add('b', TestObject('obj2', 10)); // Same value as 'a'
      tree.add('c', TestObject('obj3', 20));
      
      // The order of 'a' and 'b' is not guaranteed since they have the same value
      // But they both should come before 'c'
      final values = tree.toList().map((obj) => obj.value).toList();
      expect(values.length, equals(3));
      expect(values.where((v) => v == 10).length, equals(2));
      expect(values.last, equals(20));
    });
  });
}
