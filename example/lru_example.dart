import 'package:lru/lru.dart';

void main() async {
  // Create from existing map
  final initial = {'a': 1, 'b': 2, 'c': 3};
  final cache = LruCache.fromMap(initial, capacity: 5);
  print('Initial cache: ${cache.values()}');

  // Use getOrAdd
  final value = cache.getOrAdd('d', () => 4);
  print('Added value: $value');
  
  // Async computation
  final asyncValue = await cache.getOrAddAsync('e', () async {
    await Future.delayed(Duration(milliseconds: 100));
    return 5;
  });
  print('Async added value: $asyncValue');

  // Update existing value
  cache.update('a', (v) => v * 2);
  print('After update: ${cache.toMap()}');

  // Get statistics
  print('Cache stats: ${cache.stats()}');

  // Create a copy
  final copy = cache.copy();
  print('Copy: ${copy.values()}');

  // Adjust capacity
  cache.capacity = 3;
  print('After capacity adjustment: ${cache.values()}');
}
