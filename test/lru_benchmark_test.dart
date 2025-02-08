import 'dart:math';
import 'package:test/test.dart';
import 'package:lru/lru.dart';

void main() {
  group('LruCache Performance Tests', () {
    final random = Random();

    // Helper function to measure and report performance metrics
    void runBenchmark(String name, Function() test, {int iterations = 1}) {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < iterations; i++) {
        test();
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / iterations;
      print('$name: ${avgTime.toStringAsFixed(2)} μs per operation');
    }

    // Tests sequential write performance by inserting items in order
    // Important for bulk loading scenarios
    test('Sequential Write Performance', () {
      final cache = LruCache<int, int>(10000);

      runBenchmark('Sequential Write', () {
        for (var i = 0; i < 10000; i++) {
          cache.put(i, i);
        }
      });

      expect(cache.length, equals(10000));
    });

    // Tests random write performance to simulate real-world usage patterns
    // Important for cache warming and update scenarios
    test('Random Write Performance', () {
      final cache = LruCache<int, int>(10000);

      runBenchmark('Random Write', () {
        for (var i = 0; i < 10000; i++) {
          final key = random.nextInt(20000);
          cache.put(key, i);
        }
      });
    });

    // Tests mixed read/write operations to simulate typical usage
    // Important for understanding average case performance
    test('Mixed Operations Performance', () {
      final cache = LruCache<int, int>(5000);

      runBenchmark('Mixed Operations', () {
        for (var i = 0; i < 10000; i++) {
          final op = random.nextInt(3);
          final key = random.nextInt(10000);

          switch (op) {
            case 0:
              cache.put(key, i);
              break;
            case 1:
              cache.fetch(key);
              break;
            case 2:
              cache.remove(key);
              break;
          }
        }
      });
    });

    // Tests bulk initialization performance
    // Important for cache initialization from existing data
    test('Bulk Operations Performance', () {
      runBenchmark('Bulk Operations', () {
        final data = {for (var i in List.generate(10000, (i) => i)) i: i * 2};

        final cache = LruCache.fromMap(data, capacity: 10000);
        expect(cache.length, equals(10000));
      });
    });

    // Tests concurrent operation performance
    // Important for multi-threaded environments
    test('Concurrent Operations Performance', () async {
      final cache = LruCache<int, int>(1000);
      final futures = <Future<void>>[];

      runBenchmark('Concurrent Operations', () {
        for (var i = 0; i < 1000; i++) {
          futures.add(Future(() {
            final key = random.nextInt(2000);
            cache.put(key, i);
            cache.fetch(key);
          }));
        }
      }, iterations: 5);

      await Future.wait(futures);
    });

    // Tests weight-based eviction performance
    // Important for memory-sensitive applications
    test('Weight-based Operations Performance', () {
      final cache = LruCache<int, int>(
        1000,
        options: LruOptions(maxWeight: 5000),
      );

      runBenchmark('Weight-based Operations', () {
        for (var i = 0; i < 1000; i++) {
          final weight = random.nextInt(5) + 1;
          cache.putWithOptions(i, i, EntryOptions(weight: weight));
        }
      });
    });

    // Tests cache hit rate performance
    // Important for measuring cache effectiveness
    test('Cache Hit Rate Performance', () {
      final cache = LruCache<int, int>(1000);
      var hits = 0;
      var total = 0;

      // Warm up cache
      for (var i = 0; i < 1000; i++) {
        cache.put(i, i);
      }

      runBenchmark('Cache Access', () {
        for (var i = 0; i < 10000; i++) {
          final key = random.nextInt(2000);
          total++;
          if (cache.fetch(key) != null) hits++;
        }
      });

      final hitRate = hits / total;
      print('Cache hit rate: ${(hitRate * 100).toStringAsFixed(2)}%');
      expect(hitRate, greaterThan(0.0));
    });
  });
}
