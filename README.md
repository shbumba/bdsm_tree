# BDSM Tree

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A **B**i-**D**irectional **S**orted **M**ap **Tree** for Dart. For when your data needs structure, discipline, and a clearly defined hierarchy.

This specialized collection binds key-value pairs together, maintaining relationships where values determine the order, while keys retain control over quick access. Every element knows its place in the rigid tree structure, with clearly defined parent-child relationships.

## Features

- **Dual Control Mechanism**: Maintain strict O(1) access by key while enforcing ordered relationships between values.
- **Customizable Domination Hierarchy**: Define your own ordering rules with a custom comparator that determines which values rise to the top.
- **Explicit Node Relationships**: Uses a proper tree structure with explicit parent, left, and right references for complete control over your data's hierarchy.
- **Dynamic Discipline Adjustment**: Change the comparator at runtime and watch as the entire structure rearranges to comply with the new order.
- **Comprehensive Safe Word API**: Rich interface with methods to access elements by key or navigate the strict ordering (first, last, before, after).
- **Efficient Chain Operations**: O(log n) complexity for insertion, removal, and traversal within the rigid tree structure.
- **On-Demand Restraining**: Force tree rebalancing when underlying values change externally or when a new hierarchy needs to be established.

## Installation

Add the package to your `pubspec.yaml` file using one of the following options:

### From pub.dev (coming soon)

```yaml
dependencies:
  bdsm_tree: ^0.1.0
```

### From GitHub

Until the package is published to pub.dev, you can install it directly from GitHub:

```yaml
dependencies:
  bdsm_tree:
    git:
      url: https://github.com/shbumba/bdsm_tree.git
      ref: main  # or use a specific branch/tag/commit
```

### For Local Development

```yaml
dependencies:
  bdsm_tree:
    path: path/to/bdsm_tree
```

After adding the dependency, run:

```bash
dart pub get
```

## Usage

### Basic Usage

```dart
import 'package:bdsm_tree/bdsm_tree.dart';

void main() {
  // Create a tree that sorts strings by their length
  final tree = BDSMTree<String, String>((pair1, pair2) => 
      pair1.value.length.compareTo(pair2.value.length));
  
  // Add key-value pairs
  tree.add('id1', 'apple');
  tree.add('id2', 'banana');
  tree.add('id3', 'cherry');
  
  // Values are sorted by length
  print(tree.toList()); // ['apple', 'cherry', 'banana']
  
  // Efficient lookup by key
  print(tree["id1"]); // 'apple'
  
  // Update a value and it automatically rebalances
  tree.update('id1', (value) => 'watermelon');
  print(tree.toList()); // ['cherry', 'banana', 'watermelon']
  
  // You can also change the comparator at runtime
  tree.setComparator((pair1, pair2) => pair1.value.compareTo(pair2.value));
  print(tree.toList()); // ['banana', 'cherry', 'watermelon'] (alphabetical order)
```

### Custom Objects as Values

```dart
import 'package:bdsm_tree/bdsm_tree.dart';

class Product {
  final String name;
  final double price;
  
  Product(this.name, this.price);
  
  @override
  String toString() => 'Product{name: $name, price: \$${price.toStringAsFixed(2)}}';
}

void main() {
  // Sort products by price using a convenient factory constructor
  final tree = BDSMTree.withValueComparator<String, Product>(
      (p1, p2) => p1.price.compareTo(p2.price));
  
  tree.add('p1', Product('Laptop', 999.99));
  tree.add('p2', Product('Phone', 599.99));
  tree.add('p3', Product('Headphones', 99.99));
  
  // Cheapest products first
  print(tree.toList()); // [Product{name: Headphones, price: $99.99}, Product{name: Phone, price: $599.99}, Product{name: Laptop, price: $999.99}]
  
  // Find products in price ranges
  final firstProductAbove500 = tree.firstValueAfter((product) => product.price > 500);
  print(firstProductAbove500); // Product{name: Phone, price: $599.99}
  
  // You can also bulk add items from a Map
  final moreProducts = <String, Product>{
    'p4': Product('Tablet', 399.99),
    'p5': Product('Smart Watch', 249.99),
  };
  
  tree.addAll(moreProducts);
}

### Handling External Changes

When the values stored in the tree or the data the comparator depends on change externally:

```dart
import 'package:bdsm_tree/bdsm_tree.dart';

class WeightedItem {
  final String name;
  double weight; // Mutable weight that affects sorting
  
  WeightedItem(this.name, this.weight);
  
  @override
  String toString() => '$name (${weight.toStringAsFixed(1)})';
}

void main() {
  // Tree with elements sorted by their weight
  final tree = BDSMTree<String, WeightedItem>((pair1, pair2) => 
      pair1.value.weight.compareTo(pair2.value.weight));
  
  final itemA = WeightedItem('A', 10.0);
  final itemB = WeightedItem('B', 20.0);
  final itemC = WeightedItem('C', 30.0);
  
  tree.add('id_a', itemA);
  tree.add('id_b', itemB);
  tree.add('id_c', itemC);
  
  print(tree.toList()); // [A (10.0), B (20.0), C (30.0)]
  
  // External change: modify the weight of itemA directly
  itemA.weight = 25.0;
  
  // The tree doesn't know about this external change!
  // The order is now incorrect based on the weights
  
  // Force rebalancing to restore proper order
  tree.rebalanceAll();
  
  print(tree.toList()); // [B (20.0), A (25.0), C (30.0)]
  
  // You could also set a completely new comparator that reverses the order
  tree.setComparator((pair1, pair2) => 
      pair2.value.weight.compareTo(pair1.value.weight));
  
  print(tree.toList()); // [C (30.0), A (25.0), B (20.0)]
}
```

## API Reference

### Creation & Configuration

- `BDSMTree(Comparator<Pair<K, V>> comparator)`: Create a new tree with the given comparator.
- `BDSMTree.from(Map<K, V> map, Comparator<Pair<K, V>> comparator)`: Create a tree from a map.
- `BDSMTree.withValueComparator(Comparator<V> valueComparator)`: Create a tree with a simpler comparator that only looks at values.
- `setComparator(Comparator<Pair<K, V>> newComparator)`: Change the ordering rules at runtime and rebalance.

### Core Methods

- `add(K key, V value)`: Bind a key-value pair to the tree structure.
- `operator [](K key)`: Quickly retrieve a value by its key.
- `operator []=(K key, V value)`: Set a value for the given key.
- `removeKey(K key)`: Remove an entry by its key.
- `remove(K key)`: Alternative method to remove by key.
- `update(K key, V Function(V value) update, {V Function()? ifAbsent})`: Modify a value and reposition it in the hierarchy.
- `clear()`: Release all elements from the structure.
- `toList()`: Convert to a list with values in their ordered positions.

### Navigation Methods

- `firstKey()`, `lastKey()`: Access the key at the top or bottom of the hierarchy.
- `firstValue()`, `lastValue()`: Get the value at the top or bottom of the hierarchy.

### Neighborhood Traversal

- `firstKeyAfter(bool Function(V value) test)`: Find the first key that satisfies certain conditions.
- `lastKeyBefore(bool Function(V value) test)`: Find the last key before conditions are met.
- `firstValueAfter(bool Function(V value) test)`: Find the first value satisfying conditions.
- `lastValueBefore(bool Function(V value) test)`: Find the last value before conditions are met.

### Discipline Maintenance

- `rebalanceAll()`: Force every element to reassert its position in the hierarchy.
- `setComparator(Comparator<Pair<K, V>> newComparator)`: Impose a new ordering system and rebalance.

## How It Works

The BDSMTree implements a binary tree data structure with explicit node relationships:

1. Each data point is wrapped in a `TreeNode<K, V>` that contains:
   - The key and value
   - References to parent, left child, and right child nodes

2. The tree maintains two key structures:
   - The hierarchical tree of `TreeNode` objects starting from a root
   - A `Map<K, TreeNode<K, V>>` for O(1) lookups by key

3. When elements are added or removed:
   - Nodes are properly inserted into the tree according to the comparator
   - Parent-child relationships are maintained for proper traversal
   - The node map is updated for quick direct access

4. The `Comparator<Pair<K, V>>` determines the strict hierarchy and can be changed at runtime, causing the tree to completely restructure itself.

## When to Use BDSMTree

BDSMTree is perfect when your codebase demands:

- A **strict hierarchy** where values determine positioning but keys control access
- **Total control** over parent-child relationships in your data structure
- **Flexible dominance rules** with the ability to change sorting criteria at runtime
- **Clear boundaries** with specialized methods for finding neighboring elements
- **Safe, consensual data manipulation** with explicit methods for each type of operation
- **Discipline maintenance** through rebalancing when external factors change

It's particularly suited for scenarios where the relationships between elements are as important as the elements themselves.

## Safe Usage Guidelines

When working with BDSMTree, always follow these principles:

1. **Communication**: Document your comparators clearly so others understand the hierarchy.
2. **Consent**: Don't modify values externally without calling rebalance methods afterward.
3. **Trust**: The tree maintains its own balance; trust the algorithm rather than forcing manual reorganization.
4. **Boundaries**: Use the specialized methods rather than accessing the nodes directly.
5. **Aftercare**: Clean up your trees when they're no longer needed with the clear() method.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
