# LRU Cache for Dart

A feature-rich Least Recently Used (LRU) cache implementation in Dart.

## Features

- Fixed-size cache with LRU eviction
- Synchronous and asynchronous value computation
- Customizable usage tracking
- Cache statistics
- Support for copying and capacity adjustment
- Entry-level options (max age, weight)
- Weight-based capacity limits
- Event notifications
- Automatic expiration

## Installation

```yaml
dependencies:
  lru: ^1.0.0
```

## Usage

```dart
// Create cache
final cache = LruCache<String, int>(5);

// Basic operations
cache.put('key', 100);
final value = cache.fetch('key');

// Compute value if absent
final computed = cache.getOrAdd('key2', () => 200);

// Async computation
final asyncValue = await cache.getOrAddAsync('key3', () async {
  await Future.delayed(Duration(seconds: 1));
  return 300;
});

// Customize behavior
final options = LruOptions(
  usage: LruUsageOptions(
    fetchAddsUsage: true,
    putAddsUsage: true
  ),
  putNewItemFirst: true
);
final customCache = LruCache<String, int>(10, options: options);

// Advanced options
final options = LruOptions(
  maxWeight: 100,
  defaultEntryOptions: EntryOptions(
    maxAge: 5000, // 5 seconds
    weight: 1
  ),
  onEvent: (event) {
    print('Cache event: ${event.type}');
  }
);

final cache = LruCache<String, int>(5, options: options);

// Add heavy item
cache.putWithOptions('large', 100, EntryOptions(weight: 5));

// Add temporary item
cache.putWithOptions('temp', 200, EntryOptions(maxAge: 1000));
```

## API Reference

### Constructor Options

- `capacity` - Maximum number of items in cache
- `LruOptions` - Customize cache behavior:
  - `usage` - Control when items are marked as used
  - `putNewItemFirst` - Control item insertion position

### Methods

- `fetch(K key)` - Get value by key
- `put(K key, V value)` - Add or update value
- `getOrAdd(K key, V Function() ifAbsent)` - Get or compute value
- `getOrAddAsync(K key, Future<V> Function() ifAbsent)` - Async get or compute
- `remove(K key)` - Remove entry
- `update(K key, V Function(V) update)` - Update existing value
- `copy()` - Create cache copy
- `clear()` - Remove all entries

### EntryOptions

- `maxAge` - Entry lifetime in milliseconds
- `weight` - Entry weight for capacity calculations

### Events

Cache events are emitted for:
- Entry addition
- Entry updates
- Entry removal
- Entry expiration
