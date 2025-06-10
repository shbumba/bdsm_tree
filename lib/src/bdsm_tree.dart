import 'dart:collection';

import 'pair.dart';
import 'tree_node.dart';

/// A Bi-directional Sorted Map Tree implementation.
///
/// This data structure maintains a sorted map that allows efficient
/// bi-directional traversal and operations such as finding values
/// before or after a given key.
class BDSMTree<K, V> with IterableMixin<V> {
  TreeNode<K, V>? _root;

  final Map<K, TreeNode<K, V>> _nodeMap = <K, TreeNode<K, V>>{};

  Comparator<Pair<K, V>> _comparator;

  /// Creates a new BDSMTree with the given comparator.
  ///
  /// The comparator compares pairs of key-value to determine their relative
  /// ordering in the tree.
  BDSMTree(Comparator<Pair<K, V>> comparator) : _comparator = comparator;

  /// Sets a new comparator and rebalances the tree.
  ///
  /// Returns the current tree instance to allow for method chaining.
  BDSMTree<K, V> setComparator(Comparator<Pair<K, V>> newComparator) {
    if (identical(_comparator, newComparator)) return this;

    _comparator = newComparator;

    if (_nodeMap.isNotEmpty) {
      rebalanceAll();
    }

    return this;
  }

  factory BDSMTree.from(Map<K, V> map, Comparator<Pair<K, V>> comparator) {
    final tree = BDSMTree<K, V>(comparator);
    tree.addAll(map);
    return tree;
  }

  factory BDSMTree.fromWithValueComparator(
      Map<K, V> map, Comparator<V> valueComparator) {
    return BDSMTree<K, V>.from(
        map, (pair1, pair2) => valueComparator(pair1.value, pair2.value));
  }

  factory BDSMTree.withValueComparator(Comparator<V> valueComparator) {
    return BDSMTree<K, V>(
        (pair1, pair2) => valueComparator(pair1.value, pair2.value));
  }

  @override
  int get length => _nodeMap.length;

  @override
  bool get isEmpty => _nodeMap.isEmpty;

  @override
  bool get isNotEmpty => _nodeMap.isNotEmpty;

  V putIfAbsent(K key, V Function() ifAbsent) {
    if (containsKey(key)) {
      return _nodeMap[key]!.value;
    }

    final value = ifAbsent();
    add(key, value);
    return value;
  }

  /// Adds a new key-value pair to the tree.
  ///
  /// If the key already exists, the value is updated.
  void add(K key, V value) {
    if (containsKey(key)) {
      _updateValue(key, value);
      return;
    }

    final newNode = TreeNode<K, V>(key, value);
    _nodeMap[key] = newNode;

    if (_root == null) {
      _root = newNode;
    } else {
      _insertNode(newNode);
    }
  }

  void _updateValue(K key, V value) {
    final node = _nodeMap[key]!;
    final oldValue = node.value;

    if (_comparator(Pair(key, value), Pair(key, oldValue)) == 0) {
      node.value = value;
      return;
    }

    removeKey(key);
    add(key, value);
  }

  void addAll(Map<K, V> other) {
    other.forEach((key, value) {
      add(key, value);
    });
  }

  /// Updates the value for the given key with the result of the update function.
  ///
  /// If the key is not in the map, the ifAbsent function is called to create a new value.
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    if (containsKey(key)) {
      final updatedValue = update(_nodeMap[key]!.value);
      _updateValue(key, updatedValue);
      return updatedValue;
    }

    if (ifAbsent == null) {
      throw ArgumentError(
          'Key $key not found and no ifAbsent function provided');
    }

    final value = ifAbsent();
    add(key, value);
    return value;
  }

  void updateAll(V Function(K key, V value) updateFn) {
    final updates = <K, V>{};

    final nodeIter = _BDSMTreeNodeIterator<K, V>(this);

    while (nodeIter.moveNext()) {
      final node = nodeIter.current;
      final updatedValue = updateFn(node.key, node.value);
      updates[node.key] = updatedValue;
    }

    for (final entry in updates.entries) {
      _updateValue(entry.key, entry.value);
    }
  }

  void clear() {
    _root = null;
    _nodeMap.clear();
  }

  @override
  List<V> toList({bool growable = true}) {
    final result = growable ? <V>[] : List<V>.filled(length, null as V);
    final iter = iterator;
    var index = 0;

    while (iter.moveNext()) {
      if (growable) {
        result.add(iter.current);
      } else {
        result[index++] = iter.current;
      }
    }
    return result;
  }

  void forEachEntry(void Function(K key, V value) f) {
    if (_root == null) return;

    final nodeIter = _BDSMTreeNodeIterator<K, V>(this);

    while (nodeIter.moveNext()) {
      final node = nodeIter.current;
      f(node.key, node.value);
    }
  }

  @override
  void forEach(void Function(V element) action) {
    final iter = iterator;

    while (iter.moveNext()) {
      action(iter.current);
    }
  }

  bool containsKey(Object? key) {
    return _nodeMap.containsKey(key);
  }

  bool containsValue(Object? value) {
    final iter = iterator;
    while (iter.moveNext()) {
      if (iter.current == value) {
        return true;
      }
    }
    return false;
  }

  K? lastKey() {
    if (_root == null) return null;

    return _findRightmost(_root!).key;
  }

  K? firstKey() {
    if (_root == null) return null;

    return _findLeftmost(_root!).key;
  }

  V? get(K key) {
    final node = _nodeMap[key];
    return node?.value;
  }

  K? getKey(V value) {
    final nodeIter = _BDSMTreeNodeIterator<K, V>(this);

    while (nodeIter.moveNext()) {
      if (nodeIter.current.value == value) {
        return nodeIter.current.key;
      }
    }
    return null;
  }

  bool removeKey(K key) {
    if (!containsKey(key)) return false;

    final node = _nodeMap[key]!;
    _removeNode(node);
    _nodeMap.remove(key);

    return true;
  }

  bool removeValue(V value) {
    for (final entry in _nodeMap.entries) {
      if (entry.value.value == value) {
        return removeKey(entry.key);
      }
    }

    return false;
  }

  Iterable<V> removeAll(Iterable<V> values) {
    final removedValues = <V>[];

    for (final value in values) {
      for (final entry in _nodeMap.entries) {
        if (entry.value.value == value) {
          removeKey(entry.key);
          removedValues.add(entry.value.value);
          break;
        }
      }
    }
    return removedValues;
  }

  Iterable<V> removeWhere(bool Function(V value) test) {
    final removedValues = <V>[];
    final keysToRemove = <K>[];

    for (final entry in _nodeMap.entries) {
      if (test(entry.value.value)) {
        keysToRemove.add(entry.key);
        removedValues.add(entry.value.value);
      }
    }

    for (final key in keysToRemove) {
      removeKey(key);
    }

    return removedValues;
  }

  void rebalanceAll() {
    final values = <K, V>{};

    forEachEntry((key, value) {
      values[key] = value;
    });
    clear();
    addAll(values);
  }

  void rebalanceWhere(bool Function(V value) test) {
    final valuesToRebalance = <K, V>{};

    for (final entry in _nodeMap.entries) {
      if (test(entry.value.value)) {
        valuesToRebalance[entry.key] = entry.value.value;
      }
    }

    for (final key in valuesToRebalance.keys) {
      removeKey(key);
    }

    addAll(valuesToRebalance);
  }

  K? lastKeyBefore(K key) {
    final node = _nodeMap[key];

    if (node == null) {
      return null;
    }

    final predecessor = _findPredecessor(node);
    return predecessor?.key;
  }

  K? firstKeyAfter(K key) {
    final node = _nodeMap[key];

    if (node == null) {
      return null;
    }

    final successor = _findSuccessor(node);
    return successor?.key;
  }

  V? lastValueBefore(K key) {
    final node = _nodeMap[key];

    if (node == null) {
      return null;
    }

    final predecessor = _findPredecessor(node);
    return predecessor?.value;
  }

  V? firstValueAfter(K key) {
    final node = _nodeMap[key];

    if (node == null) {
      return null;
    }

    final successor = _findSuccessor(node);
    return successor?.value;
  }

  void _insertNode(TreeNode<K, V> newNode) {
    TreeNode<K, V> current = _root!;
    TreeNode<K, V>? parent;

    while (true) {
      parent = current;
      final compareResult = _comparator(
          Pair(newNode.key, newNode.value), Pair(current.key, current.value));

      if (compareResult < 0) {
        if (current.left == null) {
          break;
        }
        current = current.left!;
      } else {
        if (current.right == null) {
          break;
        }
        current = current.right!;
      }
    }

    newNode.parent = parent;
    final compareResult = _comparator(
        Pair(newNode.key, newNode.value), Pair(parent.key, parent.value));

    if (compareResult < 0) {
      parent.left = newNode;
    } else {
      parent.right = newNode;
    }
  }

  void _removeNode(TreeNode<K, V> node) {
    if (node.isLeaf) {
      if (node.parent == null) {
        _root = null;
      } else {
        node.replaceInParent(null);
      }

      return;
    }

    if (node.hasOneChild) {
      final child = node.left ?? node.right;

      if (node.parent == null) {
        _root = child;
        child!.parent = null;
      } else {
        node.replaceInParent(child);
      }

      return;
    }

    final successor = _findSuccessor(node)!;

    final successorKey = successor.key;
    final successorValue = successor.value;

    _removeNode(successor);

    _nodeMap.remove(successorKey);
    _nodeMap[successorKey] = node;

    node.value = successorValue;
  }

  TreeNode<K, V> _findLeftmost(TreeNode<K, V> node) {
    TreeNode<K, V> current = node;

    while (current.left != null) {
      current = current.left!;
    }

    return current;
  }

  TreeNode<K, V> _findRightmost(TreeNode<K, V> node) {
    TreeNode<K, V> current = node;

    while (current.right != null) {
      current = current.right!;
    }

    return current;
  }

  TreeNode<K, V>? _findPredecessor(TreeNode<K, V> node) {
    if (node.left != null) {
      return _findRightmost(node.left!);
    }

    TreeNode<K, V>? current = node;
    TreeNode<K, V>? parent = node.parent;

    while (parent != null && current == parent.left) {
      current = parent;
      parent = parent.parent;
    }

    return parent;
  }

  TreeNode<K, V>? _findSuccessor(TreeNode<K, V> node) {
    if (node.right != null) {
      return _findLeftmost(node.right!);
    }

    TreeNode<K, V>? current = node;
    TreeNode<K, V>? parent = node.parent;

    while (parent != null && current == parent.right) {
      current = parent;
      parent = parent.parent;
    }

    return parent;
  }

  @override
  Iterator<V> get iterator {
    return _BDSMTreeIterator<K, V>(this);
  }
}

/// Iterator for BDSMTree values in sorted order.
class _BDSMTreeIterator<K, V> implements Iterator<V> {
  final _BDSMTreeNodeIterator<K, V> _nodeIterator;

  _BDSMTreeIterator(BDSMTree<K, V> tree)
      : _nodeIterator = _BDSMTreeNodeIterator<K, V>(tree);

  @override
  V get current => _nodeIterator.current.value;

  @override
  bool moveNext() => _nodeIterator.moveNext();
}

/// Iterator for tree nodes in sorted order.
class _BDSMTreeNodeIterator<K, V> implements Iterator<TreeNode<K, V>> {
  final BDSMTree<K, V> _tree;

  final List<TreeNode<K, V>> _path = [];

  TreeNode<K, V>? _currentNode;

  bool _isValid = false;

  _BDSMTreeNodeIterator(this._tree);

  @override
  TreeNode<K, V> get current {
    if (!_isValid || _currentNode == null) {
      throw StateError('No current element');
    }
    return _currentNode!;
  }

  @override
  bool moveNext() {
    if (!_isValid) {
      _isValid = true;
      _currentNode = _tree._root;

      if (_currentNode == null) return false;

      while (_currentNode!.left != null) {
        _path.add(_currentNode!);
        _currentNode = _currentNode!.left;
      }
      return true;
    }

    if (_currentNode!.right != null) {
      _path.add(_currentNode!);
      _currentNode = _currentNode!.right;

      while (_currentNode!.left != null) {
        _path.add(_currentNode!);
        _currentNode = _currentNode!.left;
      }
      return true;
    }

    while (_path.isNotEmpty) {
      var parent = _path.removeLast();

      if (parent.left == _currentNode) {
        _currentNode = parent;
        return true;
      }
      // Otherwise, we came from the right child, continue up
      _currentNode = parent;
    }

    // If we get here, we've visited all nodes
    _currentNode = null;
    return false;
  }
}
