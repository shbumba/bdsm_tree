/// A simple pair class that holds a key-value pair.
class Pair<K, V> {
  final K key;
  final V value;

  const Pair(this.key, this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pair && other.key == key && other.value == value;
  }

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() => 'Pair($key, $value)';
}
