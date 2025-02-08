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
  });
}
