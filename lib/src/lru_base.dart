/// Each node in the doubly linked list.
/// It contains the key, value, and pointers to the previous and next nodes.
class Node<K, V> {
  K key;
  V value;
  Node<K, V>? prev;
  Node<K, V>? next;

  Node(this.key, this.value);
}

/// A LRU cache implementation.
class LRUCache<K, V> {
  final int capacity;
  final Map<K, Node<K, V>> _cache = {};
  Node<K, V>? _head;
  Node<K, V>? _tail;

  /// Create a new LRU cache with the given [capacity].
  LRUCache(this.capacity) {
    if (capacity <= 0) {
      throw ArgumentError('Capacity must be positive');
    }
  }

  /// Get the value.
  V? fetch(K key) {
    final node = _cache[key];
    if (node == null) return null;

    _moveToFront(node);
    return node.value;
  }

  /// Put a new key-value pair.
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      final node = _cache[key]!;
      node.value = value;
      _moveToFront(node);
      return;
    }

    final newNode = Node(key, value);
    _cache[key] = newNode;
    _addToFront(newNode);

    if (_cache.length > capacity) {
      _removeLRU();
    }
  }

  /// Move the node to the front of the list.
  void _moveToFront(Node<K, V> node) {
    if (node == _head) return;

    _removeNode(node);
    _addToFront(node);
  }

  /// Add a new node to the front of the list.
  void _addToFront(Node<K, V> node) {
    node.next = _head;
    node.prev = null;

    if (_head != null) {
      _head!.prev = node;
    }
    _head = node;

    _tail ??= node;
  }

  /// Remove a node from the list.
  void _removeNode(Node<K, V> node) {
    if (node.prev != null) {
      node.prev!.next = node.next;
    } else {
      _head = node.next;
    }

    if (node.next != null) {
      node.next!.prev = node.prev;
    } else {
      _tail = node.prev;
    }
  }

  /// Remove the least recently used node.
  void _removeLRU() {
    if (_tail != null) {
      _cache.remove(_tail!.key);
      _removeNode(_tail!);
    }
  }

  /// Get the number of entries in the cache.
  int get length => _cache.length;

  /// Check if the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Check if the cache is not empty.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Get all values in the cache.
  List<V> values() {
    final result = <V>[];
    var current = _head;
    while (current != null) {
      result.add(current.value);
      current = current.next;
    }
    return result;
  }

  /// Get all keys in the cache.
  List<K> keys() {
    final result = <K>[];
    var current = _head;
    while (current != null) {
      result.add(current.key);
      current = current.next;
    }
    return result;
  }

  /// Clear the cache.
  void clear() {
    _cache.clear();
    _head = null;
    _tail = null;
  }

  /// Convert the cache to a map.
  Map<K, V> toMap() {
    final result = <K, V>{};
    var current = _head;
    while (current != null) {
      result[current.key] = current.value;
      current = current.next;
    }
    return result;
  }
}
