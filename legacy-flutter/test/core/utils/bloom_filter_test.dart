import 'package:flutter_test/flutter_test.dart';
import 'package:sada/core/utils/bloom_filter.dart';

void main() {
  group('BloomFilter Tests', () {
    test('Should handle add and contains correctly', () {
      final bf = BloomFilter();
      bf.add('message1');
      bf.add('message2');
      
      expect(bf.contains('message1'), isTrue);
      expect(bf.contains('message2'), isTrue);
      expect(bf.contains('message3'), isFalse); // High probability true negative
    });

    test('Should serialize and deserialize correctly', () {
      final bf1 = BloomFilter();
      bf1.add('test1');
      bf1.add('test2');
      
      final base64 = bf1.toBase64();
      final bf2 = BloomFilter.fromBase64(base64);
      
      expect(bf2.contains('test1'), isTrue);
      expect(bf2.contains('test2'), isTrue);
      expect(bf2.contains('test3'), isFalse);
    });

    test('Should work with larger dataset', () {
      final bf = BloomFilter(sizeInBits: 8192, numHashFunctions: 5);
      final items = List.generate(100, (i) => 'item_$i');
      
      for (final item in items) {
        bf.add(item);
      }
      
      for (final item in items) {
        expect(bf.contains(item), isTrue);
      }
      
      expect(bf.contains('unknown_item'), isFalse);
    });
  });
}
