/// Each node in the doubly linked list.
///
/// It contains the key, value, and pointers to the previous and next nodes.
final class _Node<K, V> {
  K key;
  V value;
  _Node<K, V>? prev;
  _Node<K, V>? next;
  final int createdAt;
  final EntryOptions options;

  // Replaced per-node Stopwatch with a global one for efficiency
  _Node(this.key, this.value, this.options)
      : createdAt = _globalStopwatch.elapsedMilliseconds;

  bool get isExpired {
    if (options.maxAge == null) return false;
    return _globalStopwatch.elapsedMilliseconds - createdAt > options.maxAge!;
  }
}

/// Global stopwatch to measure elapsed time for all nodes
final _globalStopwatch = Stopwatch()..start();

/// Entry options for cache items
final class EntryOptions {
  /// Maximum age in milliseconds
  final int? maxAge;

  /// Weight of the entry for capacity calculations
  final int weight;

  const EntryOptions({
    this.maxAge,
    this.weight = 1,
  });
}

/// Cache event types
enum CacheEventType {
  add,
  update,
  remove,
  expired,
}

/// Cache event data
class CacheEvent<K, V> {
  final CacheEventType type;
  final K key;
  final V? value;
  final DateTime timestamp;

  CacheEvent(this.type, this.key, this.value) : timestamp = DateTime.now();
}

/// {@template lru_usage_options}
/// Usage options for the LRU cache
/// {@endtemplate}
final class LruUsageOptions {
  /// Fetch operation increases items' usage, so they are less likely to be removed
  final bool fetchAddsUsage;

  /// Put operation increases items' usage, so they are less likely to be removed
  final bool putAddsUsage;

  /// Update operation increases items' usage, so they are less likely to be removed
  final bool updateAddsUsage;

  const LruUsageOptions({
    this.fetchAddsUsage = true,
    this.putAddsUsage = true,
    this.updateAddsUsage = true,
  });
}

/// {@template lru_options}
/// Options for the LRU cache
/// {@endtemplate}
final class LruOptions<K, V> {
  /// {@macro lru_usage_options}
  final LruUsageOptions usage;

  /// Put new items at the beginning of the list.
  final bool putNewItemFirst;

  /// Maximum total weight of entries
  final int? maxWeight;

  /// Default entry options
  final EntryOptions defaultEntryOptions;

  /// Event listener
  final void Function(CacheEvent<K, V>)? onEvent;

  const LruOptions({
    this.usage = const LruUsageOptions(),
    this.putNewItemFirst = true,
    this.maxWeight,
    this.defaultEntryOptions = const EntryOptions(),
    this.onEvent,
  });
}

/// A LRU cache implementation with enhanced features
class LruCache<K, V> {
  int _capacity;
  final Map<K, _Node<K, V>> _cache;
  _Node<K, V>? _head;
  _Node<K, V>? _tail;
  final LruOptions<K, V> _options;
  int _totalWeight = 0;

  /// Create a new LRU cache with the given [capacity]
  LruCache(this._capacity, {LruOptions<K, V> options = const LruOptions()})
      : _cache = {},
        _options = options {
    if (_capacity <= 0) {
      throw ArgumentError('Capacity must be positive');
    }
    if (_options.maxWeight != null && _options.maxWeight! <= 0) {
      throw ArgumentError('Max weight must be positive');
    }
  }

  /// Create a LRU cache from an existing map
  factory LruCache.fromMap(
    Map<K, V> map, {
    int? capacity,
    LruOptions<K, V> options = const LruOptions(),
  }) {
    final cache = LruCache<K, V>(
      capacity ?? map.length,
      options: options,
    );
    map.forEach(cache.put);
    return cache;
  }

  /// Create an empty LRU cache with default capacity
  factory LruCache.empty({
    int capacity = 10,
    LruOptions<K, V> options = const LruOptions(),
  }) =>
      LruCache(capacity, options: options);

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

    if (node.isExpired) {
      remove(key);
      _options.onEvent
          ?.call(CacheEvent(CacheEventType.expired, key, node.value));
      return null;
    }

    if (_options.usage.fetchAddsUsage) {
      _moveToFront(node);
    }
    return node.value;
  }

  /// Put a new key-value pair.
  void put(K key, V value) {
    putWithOptions(key, value, _options.defaultEntryOptions);
  }

  /// Put with custom options
  void putWithOptions(K key, V value, EntryOptions options) {
    _validateWeight(options.weight);
    final node = _Node(key, value, options);

    if (_cache.containsKey(key)) {
      final existingNode = _cache[key]!;
      _totalWeight -= existingNode.options.weight;
      existingNode.value = value;
      if (_options.usage.putAddsUsage) {
        _moveToFront(existingNode);
      }
      _totalWeight += options.weight;
      _options.onEvent?.call(CacheEvent(CacheEventType.update, key, value));
      return;
    }

    _totalWeight += options.weight;
    _cache[key] = node;

    if (_options.putNewItemFirst) {
      _addToFront(node);
    } else {
      _addToBack(node);
    }

    while (_cache.length > _capacity ||
        (_options.maxWeight != null && _totalWeight > _options.maxWeight!)) {
      _removeLRU();
    }

    _options.onEvent?.call(CacheEvent(CacheEventType.add, key, value));
  }

  void _validateWeight(int weight) {
    if (weight <= 0) {
      throw ArgumentError('Entry weight must be positive');
    }

    if (_options.maxWeight != null) {
      if (_totalWeight + weight > _options.maxWeight!) {
        while (_totalWeight + weight > _options.maxWeight! && !isEmpty) {
          _removeLRU();
        }
      }
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
    _totalWeight -= node.options.weight;
    _options.onEvent?.call(CacheEvent(CacheEventType.remove, key, node.value));
    return node.value;
  }

  /// Contains key check
  bool containsKey(K key) => _cache.containsKey(key);

  /// Contains value check
  bool containsValue(V value) {
    var current = _head;
    while (current != null) {
      if (current.value == value) {
        return true;
      }
      current = current.next;
    }
    return false;
  }

  /// Update value if exists
  bool update(K key, V Function(V) update) {
    final node = _cache[key];
    if (node == null) return false;

    node.value = update(node.value);
    if (_options.usage.updateAddsUsage) {
      _moveToFront(node);
    }
    _options.onEvent?.call(CacheEvent(CacheEventType.update, key, node.value));
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
  ({int capacity, int size, double usage}) stats() => (
        capacity: _capacity,
        size: length,
        usage: length / _capacity,
  );

  /// Move the node to the front of the list.
  void _moveToFront(_Node<K, V> node) {
    if (node == _head) return;

    _removeNode(node);
    _addToFront(node);
  }

  /// Add a new node to the front of the list.
  void _addToFront(_Node<K, V> node) {
    node.next = _head;
    node.prev = null;

    if (_head != null) {
      _head!.prev = node;
    }
    _head = node;

    _tail ??= node;
  }

  /// Add a new node to the back of the list.
  void _addToBack(_Node<K, V> node) {
    node.prev = _tail;
    node.next = null;

    if (_tail != null) {
      _tail!.next = node;
    }
    _tail = node;

    _head ??= node;
  }

  /// Remove a node from the list.
  void _removeNode(_Node<K, V> node) {
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
      _totalWeight -= _tail!.options.weight;
      _cache.remove(_tail!.key);
      _removeNode(_tail!);
    }
  }

  /// Remove the least recently used [count] entries.
  /// If [count] is greater than the cache size, all entries will be removed.
  void removeLeastUsed(int count) {
    final toRemove = count.clamp(0, length);
    for (var i = 0; i < toRemove; i++) {
      if (_tail != null) {
        final key = _tail!.key;
        remove(key);
      }
    }
  }

  /// Remove the least recently used entries by percentage.
  /// [percentage] should be between 0 and 100.
  void removeLeastUsedPercent(double percentage) {
    if (percentage < 0 || percentage > 100) {
      throw ArgumentError('Percentage must be between 0 and 100');
    }
    final count = (length * percentage / 100).round();
    removeLeastUsed(count);
  }

  /// Removes all entries that satisfy the given [test].
  /// Returns the number of entries that were removed.
  int removeWhere(bool Function(K key, V value) test) {
    int removedCount = 0;
    final keysToRemove = <K>[];
    
    // First collect keys to avoid concurrent modification
    for (final entry in entries) {
      if (test(entry.key, entry.value)) {
        keysToRemove.add(entry.key);
      }
    }
    
    // Then remove the collected keys
    for (final key in keysToRemove) {
      remove(key);
      removedCount++;
    }
    
    return removedCount;
  }

  /// Get the number of entries in the cache.
  int get length => _cache.length;

  /// Check if the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Check if the cache is not empty.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Get all values in the cache.
  List<V> get values {
    final result = <V>[];
    var current = _head;
    while (current != null) {
      result.add(current.value);
      current = current.next;
    }
    return result;
  }

  /// Get all keys in the cache.
  List<K> get keys {
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
  LruCache<K, V> copy() {
    final newCache = LruCache<K, V>(_capacity);
    var current = _tail;
    while (current != null) {
      newCache.put(current.key, current.value);
      current = current.prev;
    }
    return newCache;
  }
}
