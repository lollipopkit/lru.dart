import 'package:lru/lru.dart';
import 'package:test/test.dart';

void main() {
  group('LRUCache', () {
    test('basic operations', () {
      final cache = LRUCache<String, int>(2);
      
      cache.put('a', 1);
      expect(cache.fetch('a'), equals(1));
      expect(cache.length, equals(1));
      
      cache.put('b', 2);
      expect(cache.values(), equals([2, 1]));
      
      cache.fetch('a');
      expect(cache.values(), equals([1, 2]));
    });

    test('capacity enforcement', () {
      final cache = LRUCache<String, int>(2);
      
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      
      expect(cache.fetch('a'), isNull);
      expect(cache.values(), equals([3, 2]));
    });

    test('update existing value', () {
      final cache = LRUCache<String, int>(2);
      
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('a', 3);
      
      expect(cache.values(), equals([3, 2]));
      expect(cache.length, equals(2));
    });

    test('invalid capacity', () {
      expect(() => LRUCache<String, int>(0), 
        throwsA(isA<ArgumentError>()));
    });

    test('empty cache operations', () {
      final cache = LRUCache<String, int>(2);
      
      expect(cache.isEmpty, isTrue);
      expect(cache.isNotEmpty, isFalse);
      expect(cache.fetch('a'), isNull);
      expect(cache.values(), isEmpty);
    });

    test('fromMap constructor', () {
      final map = {'a': 1, 'b': 2, 'c': 3};
      final cache = LRUCache.fromMap(map, capacity: 5);
      
      expect(cache.length, equals(3));
      expect(cache.capacity, equals(5));
      expect(cache.containsKey('a'), isTrue);
      expect(cache.fetch('b'), equals(2));
    });

    test('empty constructor', () {
      final cache = LRUCache.empty();
      expect(cache.capacity, equals(10));
      expect(cache.isEmpty, isTrue);
    });

    test('capacity adjustment', () {
      final cache = LRUCache<String, int>(5);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      
      cache.capacity = 2;
      expect(cache.length, equals(2));
      expect(cache.fetch('a'), isNull);
      
      expect(() => cache.capacity = 0, throwsArgumentError);
    });

    test('getOrAdd functionality', () {
      final cache = LRUCache<String, int>(2);
      var computeCalls = 0;
      
      final value = cache.getOrAdd('a', () {
        computeCalls++;
        return 42;
      });
      
      expect(value, equals(42));
      expect(computeCalls, equals(1));
      
      final cachedValue = cache.getOrAdd('a', () {
        computeCalls++;
        return 24;
      });
      
      expect(cachedValue, equals(42));
      expect(computeCalls, equals(1));
    });

    test('async operations', () async {
      final cache = LRUCache<String, int>(2);
      
      final value = await cache.getOrAddAsync('a', () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });
      
      expect(value, equals(42));
      expect(cache.fetch('a'), equals(42));
    });

    test('update operations', () {
      final cache = LRUCache<String, int>(2);
      cache.put('a', 1);
      
      final updated = cache.update('a', (v) => v * 2);
      expect(updated, isTrue);
      expect(cache.fetch('a'), equals(2));
      
      final notUpdated = cache.update('b', (v) => v * 2);
      expect(notUpdated, isFalse);
    });

    test('entries iteration', () {
      final cache = LRUCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      
      final entries = cache.entries.toList();
      expect(entries.length, equals(2));
      expect(entries.map((e) => e.key), containsAll(['a', 'b']));
    });

    test('cache statistics', () {
      final cache = LRUCache<String, int>(4);
      cache.put('a', 1);
      cache.put('b', 2);
      
      final stats = cache.stats();
      expect(stats['capacity'], equals(4));
      expect(stats['size'], equals(2));
      expect(stats['usage'], equals(0.5));
    });

    test('copy operation', () {
      final original = LRUCache<String, int>(3);
      original.put('a', 1);
      original.put('b', 2);
      
      final copy = original.copy();
      expect(copy.values(), equals(original.values()));
      expect(copy.capacity, equals(original.capacity));
      
      copy.put('c', 3);
      expect(copy.length, equals(3));
      expect(original.length, equals(2));
    });

    test('concurrent modifications', () async {
      final cache = LRUCache<String, int>(100);
      final futures = <Future>[];
      
      for (var i = 0; i < 100; i++) {
        futures.add(Future(() {
          cache.put('key$i', i);
          cache.fetch('key$i');
        }));
      }
      
      await Future.wait(futures);
      expect(cache.length, equals(100));
    });

    test('stress test', () {
      final cache = LRUCache<int, int>(1000);
      final stopwatch = Stopwatch()..start();
      
      for (var i = 0; i < 10000; i++) {
        cache.put(i, i);
        if (i % 2 == 0) cache.fetch(i ~/ 2);
      }
      
      stopwatch.stop();
      expect(cache.length, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('edge cases', () {
      final cache = LRUCache<String, int>(2);
      
      cache.put('', 0);
      expect(cache.fetch(''), equals(0));
      
      cache.put('a' * 1000, 1);
      expect(cache.fetch('a' * 1000), equals(1));
      
      cache.clear();
      expect(cache.isEmpty, isTrue);
      expect(cache.capacity, equals(2));
    });
  });
}
