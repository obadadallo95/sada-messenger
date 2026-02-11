import 'dart:convert';
import 'dart:typed_data';

/// فلتر بلوم (Bloom Filter) لتقليل حجم البيانات المتداولة أثناء المزامنة
/// يسمح بالتحقق الاحتمالي من وجود عنصر ما في المجموعة.
/// - False Positive: ممكن (يقول "موجود" وهو غير موجود - بنسبة ضئيلة)
/// - False Negative: مستحيل (إذا قال "غير موجود" فهو بالتأكيد غير موجود)
class BloomFilter {
  late final Uint8List _bits;
  late final int _sizeInBits;
  late final int _numHashFunctions;

  /// الحجم الافتراضي: 8192 بت (1 كيلوبايت)
  /// يكفي لـ ~1000 عنصر بنسبة خطأ ~1%
  static const int DEFAULT_SIZE = 8192;
  static const int DEFAULT_HASHES = 5;

  BloomFilter({int sizeInBits = DEFAULT_SIZE, int numHashFunctions = DEFAULT_HASHES}) {
    _sizeInBits = sizeInBits;
    _numHashFunctions = numHashFunctions;
    _bits = Uint8List((_sizeInBits + 7) ~/ 8);
  }

  /// إنشاء فلتر من Base64 (للاستقبال من الشبكة)
  factory BloomFilter.fromBase64(String base64String, {int sizeInBits = DEFAULT_SIZE, int numHashFunctions = DEFAULT_HASHES}) {
    final bytes = base64Decode(base64String);
    final filter = BloomFilter._internal();
    filter._sizeInBits = bytes.length * 8;
    filter._numHashFunctions = numHashFunctions;
    filter._bits = bytes;
    return filter;
  }

  /// Internal constructor for factory
  BloomFilter._internal();

  /// إضافة عنصر (String) إلى الفلتر
  void add(String item) {
    final itemBytes = utf8.encode(item);
    for (int i = 0; i < _numHashFunctions; i++) {
      final hash = _fnv1a(itemBytes, i);
      final index = hash % _sizeInBits;
      _setBit(index);
    }
  }

  /// التحقق من وجود عنصر
  /// Returns:
  /// - true: العنصر *ربما* موجود (Probability of False Positive)
  /// - false: العنصر *بالتأكيد* غير موجود
  bool contains(String item) {
    final itemBytes = utf8.encode(item);
    for (int i = 0; i < _numHashFunctions; i++) {
      final hash = _fnv1a(itemBytes, i);
      final index = hash % _sizeInBits;
      if (!_getBit(index)) {
        return false;
      }
    }
    return true;
  }

  /// تحويل الفلتر إلى Base64 (للإرسال عبر الشبكة)
  String toBase64() {
    return base64Encode(_bits);
  }

  /// تعيين البت في الموقع المحدد
  void _setBit(int index) {
    final byteIndex = index ~/ 8;
    final bitIndex = index % 8;
    _bits[byteIndex] |= (1 << bitIndex);
  }

  /// قراءة البت في الموقع المحدد
  bool _getBit(int index) {
    final byteIndex = index ~/ 8;
    final bitIndex = index % 8;
    return (_bits[byteIndex] & (1 << bitIndex)) != 0;
  }

  /// خوارزمية FNV-1a Hash (معدلة لإنتاج قيم متعددة باستخدام Seed/Salt)
  int _fnv1a(List<int> bytes, int seed) {
    int hash = 2166136261; // FNV offset basis
    
    // Mix the seed (salt) first
    hash ^= seed;
    hash *= 16777619; // FNV prime

    for (var byte in bytes) {
      hash ^= byte;
      hash *= 16777619;
    }
    
    // Ensure positive integer
    return hash & 0x7FFFFFFF;
  }
}
