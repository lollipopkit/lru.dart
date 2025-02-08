import 'package:lru/lru.dart';

void main() {
  // Create a LRU cache with capacity of 3
  final cache = LRUCache<String, int>(3);
  
  // Add some entries
  cache.put('a', 1);
  cache.put('b', 2);
  cache.put('c', 3);
  print('Initial cache: ${cache.values()}'); // [3, 2, 1]
  
  // Access 'a' to bring it to front
  cache.fetch('a');
  print('After accessing "a": ${cache.values()}'); // [1, 3, 2]
  
  // Add new entry when cache is full
  cache.put('d', 4);
  print('After adding "d": ${cache.values()}'); // [4, 1, 3]
}
