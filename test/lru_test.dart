import 'package:lru/lru.dart';
import 'package:test/test.dart';

void main() {
  group('LruCache', () {
    test('basic operations', () {
      final cache = LruCache<String, int>(2);

      cache.put('a', 1);
      expect(cache.fetch('a'), equals(1));
      expect(cache.length, equals(1));

      cache.put('b', 2);
      expect(cache.values(), equals([2, 1]));

      cache.fetch('a');
      expect(cache.values(), equals([1, 2]));
    });

    test('capacity enforcement', () {
      final cache = LruCache<String, int>(2);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      expect(cache.fetch('a'), isNull);
      expect(cache.values(), equals([3, 2]));
    });

    test('update existing value', () {
      final cache = LruCache<String, int>(2);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('a', 3);

      expect(cache.values(), equals([3, 2]));
      expect(cache.length, equals(2));
    });

    test('invalid capacity', () {
      expect(() => LruCache<String, int>(0), throwsA(isA<ArgumentError>()));
    });

    test('empty cache operations', () {
      final cache = LruCache<String, int>(2);

      expect(cache.isEmpty, isTrue);
      expect(cache.isNotEmpty, isFalse);
      expect(cache.fetch('a'), isNull);
      expect(cache.values(), isEmpty);
    });

    test('fromMap constructor', () {
      final map = {'a': 1, 'b': 2, 'c': 3};
      final cache = LruCache.fromMap(map, capacity: 5);

      expect(cache.length, equals(3));
      expect(cache.capacity, equals(5));
      expect(cache.containsKey('a'), isTrue);
      expect(cache.fetch('b'), equals(2));
    });

    test('empty constructor', () {
      final cache = LruCache.empty();
      expect(cache.capacity, equals(10));
      expect(cache.isEmpty, isTrue);
    });

    test('capacity adjustment', () {
      final cache = LruCache<String, int>(5);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      cache.capacity = 2;
      expect(cache.length, equals(2));
      expect(cache.fetch('a'), isNull);

      expect(() => cache.capacity = 0, throwsArgumentError);
    });

    test('getOrAdd functionality', () {
      final cache = LruCache<String, int>(2);
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
      final cache = LruCache<String, int>(2);

      final value = await cache.getOrAddAsync('a', () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });

      expect(value, equals(42));
      expect(cache.fetch('a'), equals(42));
    });

    test('update operations', () {
      final cache = LruCache<String, int>(2);
      cache.put('a', 1);

      final updated = cache.update('a', (v) => v * 2);
      expect(updated, isTrue);
      expect(cache.fetch('a'), equals(2));

      final notUpdated = cache.update('b', (v) => v * 2);
      expect(notUpdated, isFalse);
    });

    test('entries iteration', () {
      final cache = LruCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);

      final entries = cache.entries.toList();
      expect(entries.length, equals(2));
      expect(entries.map((e) => e.key), containsAll(['a', 'b']));
    });

    test('cache statistics', () {
      final cache = LruCache<String, int>(4);
      cache.put('a', 1);
      cache.put('b', 2);

      final stats = cache.stats();
      expect(stats['capacity'], equals(4));
      expect(stats['size'], equals(2));
      expect(stats['usage'], equals(0.5));
    });

    test('copy operation', () {
      final original = LruCache<String, int>(3);
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
      final cache = LruCache<String, int>(100);
      final futures = <Future<void>>[];

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
      final cache = LruCache<int, int>(1000);
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
      final cache = LruCache<String, int>(2);

      cache.put('', 0);
      expect(cache.fetch(''), equals(0));

      cache.put('a' * 1000, 1);
      expect(cache.fetch('a' * 1000), equals(1));

      cache.clear();
      expect(cache.isEmpty, isTrue);
      expect(cache.capacity, equals(2));
    });

    test('custom usage options', () {
      final options = LruOptions<String, int>(
        usage: LruUsageOptions(
          fetchAddsUsage: false,
          putAddsUsage: false,
          updateAddsUsage: false,
        ),
      );
      final cache = LruCache<String, int>(3, options: options);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Fetch shouldn't affect order
      cache.fetch('a');
      expect(cache.values(), equals([3, 2, 1]));

      // Update shouldn't affect order
      cache.update('b', (v) => v * 2);
      expect(cache.values(), equals([3, 4, 1]));

      // Put existing shouldn't affect order
      cache.put('a', 10);
      expect(cache.values(), equals([3, 4, 10]));
    });

    test('partial usage options', () {
      final options = LruOptions<String, int>(
        usage: LruUsageOptions(
          fetchAddsUsage: true,
          putAddsUsage: false,
          updateAddsUsage: true,
        ),
      );
      final cache = LruCache<String, int>(3, options: options);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Fetch should affect order
      cache.fetch('a');
      expect(cache.values(), equals([1, 3, 2]));

      // Update should affect order
      cache.update('b', (v) => v * 2);
      expect(cache.values(), equals([4, 1, 3]));

      // Put existing shouldn't affect order
      cache.put('c', 30);
      expect(cache.values(), equals([4, 1, 30]));
    });

    test('putNewItemFirst option', () {
      final optionsFirst = LruOptions<String, int>(putNewItemFirst: true);
      final cachePutFirst = LruCache<String, int>(3, options: optionsFirst);

      cachePutFirst.put('a', 1);
      cachePutFirst.put('b', 2);
      cachePutFirst.put('c', 3);
      expect(cachePutFirst.values(), equals([3, 2, 1]));

      final optionsLast = LruOptions<String, int>(putNewItemFirst: false);
      final cachePutLast = LruCache<String, int>(3, options: optionsLast);

      cachePutLast.put('a', 1);
      cachePutLast.put('b', 2);
      cachePutLast.put('c', 3);
      expect(cachePutLast.values(), equals([1, 2, 3]));
    });

    test('entry expiration', () async {
      final cache = LruCache<String, int>(
        3,
        options: LruOptions(
          defaultEntryOptions: EntryOptions(maxAge: 100),
        ),
      );

      cache.put('a', 1);
      expect(cache.fetch('a'), equals(1));

      await Future.delayed(Duration(milliseconds: 150));
      expect(cache.fetch('a'), isNull);
      expect(cache.isEmpty, isTrue);
    });

    test('custom entry options', () {
      final cache = LruCache<String, int>(3);

      cache.putWithOptions('a', 1, EntryOptions(weight: 2));
      cache.putWithOptions('b', 2, EntryOptions(maxAge: 1000));

      expect(cache.length, equals(2));
    });

    test('weight limits', () {
      final cache = LruCache<String, int>(
        5,
        options: LruOptions(maxWeight: 10),
      );

      cache.putWithOptions('a', 1, EntryOptions(weight: 5));
      cache.putWithOptions('b', 2, EntryOptions(weight: 3));
      cache.putWithOptions('c', 3, EntryOptions(weight: 4)); // Should evict 'a'

      expect(cache.fetch('a'), isNull);
      expect(cache.length, equals(2));
    });

    test('event notifications', () async {
      final events = <CacheEvent<String, int>>[];
      final cache = LruCache<String, int>(
        2,
        options: LruOptions(onEvent: events.add),
      );

      cache.put('a', 1);
      expect(events.last.type, equals(CacheEventType.add));

      cache.put('a', 2);
      expect(events.last.type, equals(CacheEventType.update));

      cache.remove('a');
      expect(events.last.type, equals(CacheEventType.remove));

      cache.putWithOptions('b', 1, EntryOptions(maxAge: 1));
      events.clear();

      // Wait for expiration
      await Future.delayed(Duration(milliseconds: 2));
      cache.fetch('b');
      expect(events.last.type, equals(CacheEventType.expired));
    });

    test('mixed expiration times', () async {
      final cache = LruCache<String, int>(3);

      cache.putWithOptions('a', 1, EntryOptions(maxAge: 50));
      cache.putWithOptions('b', 2, EntryOptions(maxAge: 150));
      cache.putWithOptions('c', 3, EntryOptions(maxAge: 250));

      await Future.delayed(Duration(milliseconds: 100));
      expect(cache.fetch('a'), isNull);
      expect(cache.fetch('b'), equals(2));
      expect(cache.fetch('c'), equals(3));

      await Future.delayed(Duration(milliseconds: 100));
      expect(cache.fetch('b'), isNull);
      expect(cache.fetch('c'), equals(3));
    });

    test('weight based eviction order', () {
      final cache = LruCache<String, int>(
        5,
        options: LruOptions(maxWeight: 10),
      );

      cache.putWithOptions('a', 1, EntryOptions(weight: 3));
      cache.putWithOptions('b', 2, EntryOptions(weight: 3));
      cache.putWithOptions('c', 3, EntryOptions(weight: 3));
      cache.putWithOptions('d', 4, EntryOptions(weight: 3));

      expect(cache.length, equals(3));
      expect(cache.fetch('a'), isNull);
    });

    test('error conditions', () {
      final cache = LruCache<String, int>(2);

      expect(() => cache.putWithOptions('a', 1, EntryOptions(weight: -1)),
          throwsArgumentError);

      expect(() => cache.capacity = -1, throwsArgumentError);

      expect(
          () => LruCache<String, int>(
                2,
                options: LruOptions(maxWeight: -1),
              ),
          throwsArgumentError);
    });

    test('containsValue test', () {
      final cache = LruCache<String, int>(3);

      cache.put('a', 1);
      cache.put('b', 2);

      expect(cache.containsValue(1), isTrue);
      expect(cache.containsValue(3), isFalse);
    });

    test('removeLeastUsed functionality', () {
      final cache = LruCache<String, int>(5);
      for (var i = 0; i < 5; i++) {
        cache.put('key$i', i);
      }
      
      // Remove 2 least used items
      cache.removeLeastUsed(2);
      expect(cache.length, equals(3));
      expect(cache.fetch('key0'), isNull);
      expect(cache.fetch('key1'), isNull);
      expect(cache.fetch('key2'), equals(2));
    });

    test('removeLeastUsedPercent functionality', () {
      final cache = LruCache<String, int>(10);
      for (var i = 0; i < 10; i++) {
        cache.put('key$i', i);
      }
      
      // Remove 30% of least used items
      cache.removeLeastUsedPercent(30);
      expect(cache.length, equals(7));
      
      expect(() => cache.removeLeastUsedPercent(-1), throwsArgumentError);
      expect(() => cache.removeLeastUsedPercent(101), throwsArgumentError);
    });
  });
}
