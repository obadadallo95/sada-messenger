import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/log_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// خدمة Discovery مجهولة الهوية
/// تولد ServiceId عشوائي لإخفاء هوية المستخدم الحقيقي
class DiscoveryService {
  static const String _serviceIdKey = 'mesh_service_id';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedServiceId;

  /// الحصول على ServiceId المجهول (يتم توليده مرة واحدة ويُحفظ)
  Future<String> getAnonymousServiceId() async {
    if (_cachedServiceId != null) {
      return _cachedServiceId!;
    }

    try {
      // محاولة قراءة ServiceId المحفوظ
      final storedId = await _storage.read(key: _serviceIdKey);
      
      if (storedId != null && storedId.isNotEmpty) {
        _cachedServiceId = storedId;
        LogService.info('تم تحميل ServiceId المحفوظ');
        return _cachedServiceId!;
      }

      // توليد ServiceId جديد عشوائي
      _cachedServiceId = _generateRandomServiceId();
      await _storage.write(key: _serviceIdKey, value: _cachedServiceId!);
      
      LogService.info('تم توليد ServiceId جديد: ${_cachedServiceId!.substring(0, 8)}...');
      return _cachedServiceId!;
    } catch (e) {
      LogService.error('خطأ في الحصول على ServiceId', e);
      // Fallback: توليد ServiceId مؤقت
      _cachedServiceId = _generateRandomServiceId();
      return _cachedServiceId!;
    }
  }

  /// توليد ServiceId عشوائي
  /// Format: "SADA-XXXX-XXXX-XXXX" (16 حرف عشوائي)
  String _generateRandomServiceId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    
    final segments = List.generate(3, (_) {
      return List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    });
    
    return 'SADA-${segments.join('-')}';
  }

  /// إعادة تعيين ServiceId (للتغيير الدوري)
  Future<String> resetServiceId() async {
    try {
      _cachedServiceId = _generateRandomServiceId();
      await _storage.write(key: _serviceIdKey, value: _cachedServiceId!);
      LogService.info('تم إعادة تعيين ServiceId: ${_cachedServiceId!.substring(0, 8)}...');
      return _cachedServiceId!;
    } catch (e) {
      LogService.error('خطأ في إعادة تعيين ServiceId', e);
      return _cachedServiceId ?? _generateRandomServiceId();
    }
  }

  /// Hash UserId لإخفاء الهوية الحقيقية
  /// يستخدم فقط للتحقق من الاتصال مع جهات الاتصال المعروفة
  Future<String> hashUserId(String userId) async {
    // استخدام hash بسيط (في الإنتاج، استخدم SHA-256)
    final bytes = utf8.encode(userId);
    int hash = 0;
    for (final byte in bytes) {
      hash = ((hash << 5) - hash) + byte;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs().toRadixString(36).toUpperCase();
  }
}

/// Provider لـ DiscoveryService
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService();
});

