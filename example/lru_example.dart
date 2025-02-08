import 'package:lru/lru.dart';

void main() async {
  // Create with advanced options
  final options = LruOptions(
    maxWeight: 10,
    defaultEntryOptions: EntryOptions(maxAge: 5000), // 5 seconds
    onEvent: (event) {
      print('Cache event: ${event.type} - Key: ${event.key}');
    },
  );

  final cache = LruCache<String, int>(5, options: options);

  // Add entry with custom options
  cache.putWithOptions('large', 100, EntryOptions(weight: 5));

  // Add entry with default max age
  cache.put('temp', 200);

  print('Initial: ${cache.toMap()}');

  // Wait for expiration
  await Future.delayed(Duration(seconds: 6));
  print('After expiration: ${cache.toMap()}');

  // Test weight limits
  cache.putWithOptions('w1', 1, EntryOptions(weight: 4));
  cache.putWithOptions('w2', 2, EntryOptions(weight: 4));
  cache.putWithOptions(
    'w3',
    3,
    EntryOptions(weight: 4),
  ); // Will trigger eviction

  print('After weight limit: ${cache.toMap()}');

  // Basic operations
  cache.put('a', 1);
  cache.put('b', 2);
  print('Initial: ${cache.toMap()}');

  // Fetch existing value
  final value = cache.fetch('a');
  print('Fetched: $value');

  // Compute if absent
  final computed = cache.getOrAdd('c', () => 3 * 2);
  print('Computed: $computed');

  // Async computation
  final asyncValue = await cache.getOrAddAsync('d', () async {
    await Future.delayed(Duration(milliseconds: 100));
    return 8;
  });
  print('Async computed: $asyncValue');

  // Update existing
  cache.update('b', (v) => v * 3);
  print('After update: ${cache.toMap()}');

  // Capacity handling
  cache.put('e', 5);
  cache.put('f', 6); // Will trigger eviction
  print('After eviction: ${cache.toMap()}');

  // Statistics
  print('Stats: ${cache.stats()}');

  // Create copy and modify
  final copy = cache.copy();
  copy.put('g', 7);
  print('Original: ${cache.toMap()}');
  print('Copy: ${copy.toMap()}');
}
