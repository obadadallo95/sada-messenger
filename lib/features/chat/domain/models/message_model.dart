/// حالة الرسالة
enum MessageStatus {
  draft,     // لم تُرسل بعد (في وضع التحرير فقط - لا تُستخدم عادةً في قاعدة البيانات)
  sending,   // قيد الإرسال إلى شبكة الـ Mesh / Relay
  sent,      // تم الإرسال إلى شبكة الـ Mesh (لكن لم يتم تأكيد التسليم النهائي بعد)
  delivered, // تم التسليم للطرف المستقبل (على هذا الجهاز)
  read,      // تم القراءة
  failed,    // فشل الإرسال
}

/// نموذج الرسالة (Message)
/// يحتوي على معلومات الرسالة في المحادثة
class MessageModel {
  final String id;
  final String text; // النص العادي (يتم فك التشفير عند التحميل)
  final String? encryptedText; // النص المشفر (يُحفظ في قاعدة البيانات)
  final bool isMe;
  final DateTime timestamp;
  final MessageStatus status;
  final String? senderName; // اسم المرسل (للمجموعات)
  final int? senderColor; // لون المرسل (للمجموعات)

  const MessageModel({
    required this.id,
    required this.text,
    this.encryptedText,
    required this.isMe,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.senderName,
    this.senderColor,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      encryptedText: json['encryptedText'] as String?,
      isMe: json['isMe'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      senderName: json['senderName'] as String?,
      senderColor: json['senderColor'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'encryptedText': encryptedText,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'senderName': senderName,
      'senderColor': senderColor,
    };
  }

  MessageModel copyWith({
    String? id,
    String? text,
    String? encryptedText,
    bool? isMe,
    DateTime? timestamp,
    MessageStatus? status,
    String? senderName,
    int? senderColor,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      encryptedText: encryptedText ?? this.encryptedText,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      senderName: senderName ?? this.senderName,
      senderColor: senderColor ?? this.senderColor,
    );
  }

  /// إنشاء نسخة مع نص مشفر
  MessageModel copyWithEncrypted(String encrypted) {
    return MessageModel(
      id: id,
      text: text,
      encryptedText: encrypted,
      isMe: isMe,
      timestamp: timestamp,
      status: status,
    );
  }
}

