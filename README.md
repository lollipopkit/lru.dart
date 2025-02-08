English | [简体中文](./README.zh.md)

# LRU

A Least Recently Used (LRU) cache implementation in Dart.

## Features

- Fixed-size cache with LRU eviction policy
- Weight-based capacity management
- Entry expiration with configurable TTL
- Event notifications for cache operations

## Quick Start

```dart
// Create a simple cache
final cache = LruCache<String, int>(5);

// Basic operations
cache.put('key', 100);
final value = cache.fetch('key');  // Returns 100
cache.remove('key');               // Removes the entry

// Check existence
if (cache.containsKey('key')) {
  // Key exists
}

// Get all entries
final values = cache.values();
final keys = cache.keys();
```

## Advanced Usage

### Automatic Value Computation

```dart
// Compute value if absent
final value = cache.getOrAdd('key', () {
  return computeExpensiveValue();
});

// Async computation
final value = await cache.getOrAddAsync('key', () async {
  return await fetchValueFromNetwork();
});
```

### Weight-Based Eviction

```dart
final options = LruOptions(
  maxWeight: 1000,
  defaultEntryOptions: EntryOptions(weight: 1)
);

final cache = LruCache<String, int>(50, options: options);

// Add heavy items
cache.putWithOptions('large', 100, EntryOptions(weight: 10));
cache.putWithOptions('small', 200, EntryOptions(weight: 1));
```

### Entry Expiration

```dart
// Global expiration
final cache = LruCache<String, int>(100, 
  options: LruOptions(
    defaultEntryOptions: EntryOptions(maxAge: 5000) // 5 seconds
  )
);

// Per-entry expiration
cache.putWithOptions('temp', 100, 
  EntryOptions(maxAge: 1000) // 1 second
);
```

### Event Handling

```dart
final cache = LruCache<String, int>(100,
  options: LruOptions(
    onEvent: (event) {
      switch (event.type) {
        case CacheEventType.add:
          print('Added: ${event.key} = ${event.value}');
          break;
        case CacheEventType.expired:
          print('Expired: ${event.key}');
          break;
      }
    }
  )
);
```

### Custom Usage Tracking

```dart
final options = LruOptions(
  usage: LruUsageOptions(
    fetchAddsUsage: true,    // Access updates position
    putAddsUsage: false,     // Put doesn't update position
    updateAddsUsage: true    // Update updates position
  )
);

final cache = LruCache<String, int>(100, options: options);
```

## Performance Tips

- Use appropriate capacity based on your memory constraints
- Configure weights for better memory management
- Consider disabling usage tracking for write-heavy scenarios
- Use bulk operations when possible
- Monitor cache statistics for optimal performance

## License
```
MIT License lollipopkit
```
