/// Each node in the doubly linked list.
/// It contains the key, value, and pointers to the previous and next nodes.
class Node<K, V> {
  K key;
  V value;
  Node<K, V>? prev;
  Node<K, V>? next;

  Node(this.key, this.value);
}

/// A LRU cache implementation with enhanced features
class LRUCache<K, V> {
  int _capacity;
  final Map<K, Node<K, V>> _cache;
  Node<K, V>? _head;
  Node<K, V>? _tail;
  
  /// Create a new LRU cache with the given [capacity]
  LRUCache(this._capacity) : _cache = {} {
    if (_capacity <= 0) {
      throw ArgumentError('Capacity must be positive');
    }
  }

  /// Create a LRU cache from an existing map
  factory LRUCache.fromMap(Map<K, V> map, {int? capacity}) {
    final cache = LRUCache<K, V>(capacity ?? map.length);
    map.forEach(cache.put);
    return cache;
  }

  /// Create an empty LRU cache with default capacity
  factory LRUCache.empty({int capacity = 10}) => LRUCache(capacity);

  /// Get or update capacity
  int get capacity => _capacity;
  set capacity(int newCapacity) {
    if (newCapacity <= 0) {
      throw ArgumentError('Capacity must be positive');
    }
    if (newCapacity < _capacity) {
      while (_cache.length > newCapacity) {
        _removeLRU();
      }
    }
    _capacity = newCapacity;
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

    if (_cache.length > _capacity) {
      _removeLRU();
    }
  }

  /// Get the value or compute it if absent
  V getOrAdd(K key, V Function() ifAbsent) {
    final value = fetch(key);
    if (value != null) return value;
    
    final newValue = ifAbsent();
    put(key, newValue);
    return newValue;
  }

  /// Get value asynchronously with a computation function
  Future<V> getOrAddAsync(K key, Future<V> Function() ifAbsent) async {
    final value = fetch(key);
    if (value != null) return value;
    
    final newValue = await ifAbsent();
    put(key, newValue);
    return newValue;
  }

  /// Remove an entry from the cache
  V? remove(K key) {
    final node = _cache[key];
    if (node == null) return null;
    
    _removeNode(node);
    _cache.remove(key);
    return node.value;
  }

  /// Contains key check
  bool containsKey(K key) => _cache.containsKey(key);

  /// Update value if exists
  bool update(K key, V Function(V) update) {
    final node = _cache[key];
    if (node == null) return false;
    
    node.value = update(node.value);
    _moveToFront(node);
    return true;
  }

  /// Get entries as iterable
  Iterable<MapEntry<K, V>> get entries sync* {
    var current = _head;
    while (current != null) {
      yield MapEntry(current.key, current.value);
      current = current.next;
    }
  }

  /// Get cache statistics
  Map<String, num> stats() => {
    'capacity': capacity,
    'size': length,
    'usage': length / capacity,
  };

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

  /// Create a copy of this cache
  LRUCache<K, V> copy() {
    final newCache = LRUCache<K, V>(_capacity);
    var current = _tail;
    while (current != null) {
      newCache.put(current.key, current.value);
      current = current.prev;
    }
    return newCache;
  }
}
