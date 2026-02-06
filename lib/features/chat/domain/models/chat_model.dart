/// نموذج المحادثة (Chat)
/// يحتوي على معلومات المحادثة الأساسية
class ChatModel {
  final String id;
  final String name;
  final String? lastMessage;
  final DateTime time;
  final int unreadCount;
  final int avatarColor; // Color value as int
  final String? avatarUrl; // Optional avatar image URL
  final String? publicKey; // PublicKey للطرف الآخر (للتشفير E2E)
  
  // Group fields
  final bool isGroup;
  final String? groupOwnerId; // معرف منشئ المجموعة
  final String? groupName; // اسم المجموعة (إذا كانت مجموعة)
  final String? groupDescription; // وصف المجموعة
  final bool isPublic; // هل المجموعة عامة؟
  final int? memberCount; // عدد الأعضاء (للمجموعات)

  const ChatModel({
    required this.id,
    required this.name,
    this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    required this.avatarColor,
    this.avatarUrl,
    this.publicKey,
    this.isGroup = false,
    this.groupOwnerId,
    this.groupName,
    this.groupDescription,
    this.isPublic = false,
    this.memberCount,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      name: json['name'] as String,
      lastMessage: json['lastMessage'] as String?,
      time: DateTime.parse(json['time'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      avatarColor: json['avatarColor'] as int,
      avatarUrl: json['avatarUrl'] as String?,
      publicKey: json['publicKey'] as String?,
      isGroup: json['isGroup'] as bool? ?? false,
      groupOwnerId: json['groupOwnerId'] as String?,
      groupName: json['groupName'] as String?,
      groupDescription: json['groupDescription'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      memberCount: json['memberCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastMessage': lastMessage,
      'time': time.toIso8601String(),
      'unreadCount': unreadCount,
      'avatarColor': avatarColor,
      'avatarUrl': avatarUrl,
      'publicKey': publicKey,
      'isGroup': isGroup,
      'groupOwnerId': groupOwnerId,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'isPublic': isPublic,
      'memberCount': memberCount,
    };
  }
  
  /// إنشاء نسخة من ChatModel مع تحديثات
  ChatModel copyWith({
    String? id,
    String? name,
    String? lastMessage,
    DateTime? time,
    int? unreadCount,
    int? avatarColor,
    String? avatarUrl,
    String? publicKey,
    bool? isGroup,
    String? groupOwnerId,
    String? groupName,
    String? groupDescription,
    bool? isPublic,
    int? memberCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      publicKey: publicKey ?? this.publicKey,
      isGroup: isGroup ?? this.isGroup,
      groupOwnerId: groupOwnerId ?? this.groupOwnerId,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      isPublic: isPublic ?? this.isPublic,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}

