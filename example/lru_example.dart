import 'package:lru/lru.dart';

void main() async {
  // Create with custom options
  final options = LruOptions(
    usage: LruUsageOptions(
      fetchAddsUsage: true,
      putAddsUsage: false,
      updateAddsUsage: true
    ),
    putNewItemFirst: false
  );
  
  // Initialize cache
  final cache = LruCache<String, int>(5, options: options);
  
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
