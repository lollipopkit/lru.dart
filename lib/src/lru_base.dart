/// Each node in the doubly linked list.
/// It contains the key, value, and pointers to the previous and next nodes.
final class _Node<K, V> {
  K key;
  V value;
  _Node<K, V>? prev;
  _Node<K, V>? next;
  final DateTime created;
  final EntryOptions options;

  _Node(this.key, this.value, this.options) : created = DateTime.now();
  
  bool get isExpired {
    if (options.maxAge == null) return false;
    return DateTime.now().difference(created).inMilliseconds > options.maxAge!;
  }
}

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
final class LruOptions {
  /// {@macro lru_usage_options}
  final LruUsageOptions usage;

  /// Put new items at the beginning of the list.
  final bool putNewItemFirst;
  
  /// Maximum total weight of entries
  final int? maxWeight;
  
  /// Default entry options
  final EntryOptions defaultEntryOptions;
  
  /// Event listener
  final void Function(CacheEvent)? onEvent;

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
  final LruOptions _options;

  /// Create a new LRU cache with the given [capacity]
  LruCache(this._capacity, {LruOptions options = const LruOptions()})
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
    LruOptions options = const LruOptions(),
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
    LruOptions options = const LruOptions(),
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
      _options.onEvent?.call(CacheEvent(CacheEventType.expired, key, node.value));
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
      existingNode.value = value;
      if (_options.usage.putAddsUsage) {
        _moveToFront(existingNode);
      }
      _options.onEvent?.call(CacheEvent(CacheEventType.update, key, value));
      return;
    }

    _cache[key] = node;
    if (_options.putNewItemFirst) {
      _addToFront(node);
    } else {
      _addToBack(node);
    }

    if (_cache.length > _capacity) {
      _removeLRU();
    }

    _options.onEvent?.call(CacheEvent(CacheEventType.add, key, value));
  }

  void _validateWeight(int weight) {
    if (weight <= 0) {
      throw ArgumentError('Entry weight must be positive');
    }
    
    if (_options.maxWeight != null) {
      final currentWeight = _getCurrentWeight();
      if (currentWeight + weight > _options.maxWeight!) {
        while (_getCurrentWeight() + weight > _options.maxWeight!) {
          _removeLRU();
        }
      }
    }
  }

  int _getCurrentWeight() {
    return _cache.values.fold(0, (sum, node) => sum + node.options.weight);
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
    _options.onEvent?.call(CacheEvent(CacheEventType.remove, key, node.value));
    return node.value;
  }

  /// Contains key check
  bool containsKey(K key) => _cache.containsKey(key);

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
  Map<String, num> stats() => {
        'capacity': capacity,
        'size': length,
        'usage': length / capacity,
      };

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
