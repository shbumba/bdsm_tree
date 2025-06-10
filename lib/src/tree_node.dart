/// A node in the BDSMTree.
///
/// This class is internal to the implementation and should not be
/// exposed to users directly.
class TreeNode<K, V> {
  final K key;

  V value;

  TreeNode<K, V>? parent;

  TreeNode<K, V>? left;

  TreeNode<K, V>? right;

  TreeNode(this.key, this.value);

  bool get isLeaf => left == null && right == null;

  bool get hasOneChild =>
      (left == null && right != null) || (left != null && right == null);

  bool get hasTwoChildren => left != null && right != null;

  int get childCount => (left != null ? 1 : 0) + (right != null ? 1 : 0);

  /// Replaces this node with the given replacement in its parent.
  ///
  /// Returns true if the replacement was successful.
  bool replaceInParent(TreeNode<K, V>? replacement) {
    if (parent == null) return false;

    if (parent!.left == this) {
      parent!.left = replacement;
    } else if (parent!.right == this) {
      parent!.right = replacement;
    } else {
      return false;
    }

    if (replacement != null) {
      replacement.parent = parent;
    }

    return true;
  }

  @override
  String toString() => 'TreeNode(key: $key, value: $value)';
}
