import 'dart:convert';

/// نموذج رسالة Mesh مع routing metadata
/// يدعم Store-Carry-Forward Mesh Routing Protocol
class MeshMessage {
  static const String typeContactExchange = 'CONTACT_EXCHANGE';
  static const String typeAck = 'ACK';
  /// معرف فريد للرسالة (للتكرار)
  final String messageId;
  
  /// معرف المرسل الأصلي (الذي أنشأ الرسالة)
  final String originalSenderId;
  
  /// معرف الوجهة النهائية (المستقبل المقصود)
  final String finalDestinationId;
  
  /// المحتوى المشفر (Base64)
  final String encryptedContent;
  
  /// عدد القفزات الحالي (TTL)
  final int hopCount;
  
  /// الحد الأقصى للقفزات (TTL)
  final int maxHops;
  
  /// قائمة معرفات الأجهزة التي مرت بها الرسالة (لمنع الحلقات)
  final List<String> trace;
  
  /// الطابع الزمني (للتخلص من الرسائل القديمة)
  final DateTime timestamp;
  
  /// نوع الرسالة (message, friend_added, etc.)
  final String? type;
  
  /// بيانات إضافية (JSON)
  final Map<String, dynamic>? metadata;

  const MeshMessage({
    required this.messageId,
    required this.originalSenderId,
    required this.finalDestinationId,
    required this.encryptedContent,
    this.hopCount = 0,
    this.maxHops = 10,
    this.trace = const [],
    required this.timestamp,
    this.type,
    this.metadata,
  });

  /// إنشاء MeshMessage من JSON
  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      messageId: json['messageId'] as String,
      originalSenderId: json['originalSenderId'] as String,
      finalDestinationId: json['finalDestinationId'] as String,
      encryptedContent: json['encryptedContent'] as String,
      hopCount: json['hopCount'] as int? ?? 0,
      maxHops: json['maxHops'] as int? ?? 10,
      trace: List<String>.from(json['trace'] as List? ?? []),
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// تحويل MeshMessage إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'originalSenderId': originalSenderId,
      'finalDestinationId': finalDestinationId,
      'encryptedContent': encryptedContent,
      'hopCount': hopCount,
      'maxHops': maxHops,
      'trace': trace,
      'timestamp': timestamp.toIso8601String(),
      if (type != null) 'type': type,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// تحويل MeshMessage إلى JSON String
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// إنشاء نسخة جديدة مع قفزة إضافية
  MeshMessage addHop(String deviceId) {
    return MeshMessage(
      messageId: messageId,
      originalSenderId: originalSenderId,
      finalDestinationId: finalDestinationId,
      encryptedContent: encryptedContent,
      hopCount: hopCount + 1,
      maxHops: maxHops,
      trace: [...trace, deviceId],
      timestamp: timestamp,
      type: type,
      metadata: metadata,
    );
  }

  /// التحقق من صحة الرسالة (TTL و Loop Detection)
  bool isValid(String myDeviceId) {
    // التحقق من TTL
    if (hopCount >= maxHops) {
      return false;
    }
    
    // التحقق من الحلقات (Loop Detection)
    if (trace.contains(myDeviceId)) {
      return false;
    }
    
    // التحقق من العمر (أكثر من 24 ساعة = قديم)
    final age = DateTime.now().difference(timestamp);
    if (age.inHours > 24) {
      return false;
    }
    
    return true;
  }

  /// التحقق من أن الرسالة موجهة لهذا الجهاز
  bool isForMe(String myDeviceId) {
    return finalDestinationId == myDeviceId;
  }

  /// التحقق من أن الرسالة من هذا الجهاز (لمنع إعادة إرسال رسائلنا)
  bool isFromMe(String myDeviceId) {
    return originalSenderId == myDeviceId;
  }

  @override
  String toString() {
    return 'MeshMessage(id: $messageId, from: $originalSenderId, to: $finalDestinationId, hops: $hopCount/$maxHops)';
  }
}

