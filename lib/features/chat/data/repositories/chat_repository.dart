import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';

part 'chat_repository.g.dart';

/// Repository للمحادثات
/// يوفر بيانات تجريبية (Mock Data) للمحادثات والرسائل
@riverpod
class ChatRepository extends _$ChatRepository {
  @override
  Future<List<ChatModel>> build() async {
    // محاكاة تأخير بسيط
    await Future.delayed(const Duration(milliseconds: 500));
    return _generateMockChats();
  }

  /// إنشاء قائمة محادثات تجريبية
  List<ChatModel> _generateMockChats() {
    final now = DateTime.now();
    
    return [
      ChatModel(
        id: '1',
        name: 'أحمد',
        lastMessage: 'مرحباً، كيف حالك؟',
        time: now.subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        avatarColor: Colors.blue.value,
      ),
      ChatModel(
        id: '2',
        name: 'سارة',
        lastMessage: 'شكراً لك على المساعدة',
        time: now.subtract(const Duration(hours: 1)),
        unreadCount: 0,
        avatarColor: Colors.pink.value,
      ),
      ChatModel(
        id: '3',
        name: 'محمد',
        lastMessage: 'نلتقي غداً في المقهى',
        time: now.subtract(const Duration(hours: 2)),
        unreadCount: 1,
        avatarColor: Colors.green.value,
      ),
      ChatModel(
        id: '4',
        name: 'فاطمة',
        lastMessage: 'الرسالة وصلت بنجاح',
        time: now.subtract(const Duration(hours: 3)),
        unreadCount: 0,
        avatarColor: Colors.purple.value,
      ),
      ChatModel(
        id: '5',
        name: 'خالد',
        lastMessage: 'هل يمكنك إرسال الملف؟',
        time: now.subtract(const Duration(days: 1)),
        unreadCount: 3,
        avatarColor: Colors.orange.value,
      ),
      ChatModel(
        id: '6',
        name: 'ليلى',
        lastMessage: 'شكراً جزيلاً',
        time: now.subtract(const Duration(days: 2)),
        unreadCount: 0,
        avatarColor: Colors.teal.value,
      ),
      ChatModel(
        id: '7',
        name: 'يوسف',
        lastMessage: 'حسناً، سأرسلها الآن',
        time: now.subtract(const Duration(days: 3)),
        unreadCount: 0,
        avatarColor: Colors.indigo.value,
      ),
      ChatModel(
        id: '8',
        name: 'نور',
        lastMessage: 'ممتاز!',
        time: now.subtract(const Duration(days: 4)),
        unreadCount: 0,
        avatarColor: Colors.red.value,
      ),
    ];
  }

  /// الحصول على رسائل محادثة معينة
  Future<List<MessageModel>> getMessages(String chatId) async {
    // محاكاة تأخير بسيط
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateMockMessages(chatId);
  }

  /// إنشاء رسائل تجريبية لمحادثة معينة
  List<MessageModel> _generateMockMessages(String chatId) {
    final now = DateTime.now();
    
    // رسائل مختلفة حسب المحادثة
    final messages = <MessageModel>[];
    
    switch (chatId) {
      case '1': // أحمد
        messages.addAll([
          MessageModel(
            id: 'm1',
            text: 'مرحباً، كيف حالك؟',
            isMe: false,
            timestamp: now.subtract(const Duration(minutes: 10)),
            status: MessageStatus.read,
          ),
          MessageModel(
            id: 'm2',
            text: 'أنا بخير، شكراً لك',
            isMe: true,
            timestamp: now.subtract(const Duration(minutes: 9)),
            status: MessageStatus.read,
          ),
          MessageModel(
            id: 'm3',
            text: 'ممتاز! هل تريد أن نلتقي اليوم؟',
            isMe: false,
            timestamp: now.subtract(const Duration(minutes: 8)),
            status: MessageStatus.read,
          ),
          MessageModel(
            id: 'm4',
            text: 'نعم، بالتأكيد',
            isMe: true,
            timestamp: now.subtract(const Duration(minutes: 7)),
            status: MessageStatus.delivered,
          ),
          MessageModel(
            id: 'm5',
            text: 'حسناً، سأرسل لك العنوان',
            isMe: false,
            timestamp: now.subtract(const Duration(minutes: 5)),
            status: MessageStatus.read,
          ),
        ]);
        break;
      default:
        // رسائل افتراضية
        messages.addAll([
          MessageModel(
            id: 'm1',
            text: 'مرحباً',
            isMe: false,
            timestamp: now.subtract(const Duration(hours: 2)),
            status: MessageStatus.read,
          ),
          MessageModel(
            id: 'm2',
            text: 'مرحباً، كيف يمكنني مساعدتك؟',
            isMe: true,
            timestamp: now.subtract(const Duration(hours: 2, minutes: -5)),
            status: MessageStatus.read,
          ),
          MessageModel(
            id: 'm3',
            text: 'شكراً لك',
            isMe: false,
            timestamp: now.subtract(const Duration(hours: 1)),
            status: MessageStatus.read,
          ),
        ]);
    }
    
    return messages;
  }
}

