import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/mesh_gradient_background.dart';
import '../../../../core/database/database_provider.dart';
import '../../domain/models/chat_model.dart';
import '../../data/repositories/messages_provider.dart';
import '../../application/chat_controller.dart';
import '../widgets/message_bubble.dart';

/// شاشة تفاصيل المحادثة
class ChatDetailsScreen extends ConsumerStatefulWidget {
  final ChatModel chat;

  const ChatDetailsScreen({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends ConsumerState<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      // إرسال الرسالة عبر ChatController
      final controller = ref.read(chatControllerProvider.notifier);
      
      // الحصول على peerId من قاعدة البيانات إذا كانت المحادثة فردية
      String? peerId;
      if (!widget.chat.isGroup) {
        try {
          final database = await ref.read(appDatabaseProvider.future);
          final chatData = await database.getChatById(widget.chat.id);
          peerId = chatData?.peerId;
        } catch (e) {
          // في حالة الفشل، نترك peerId = null وChatController سيتعامل معه
          peerId = null;
        }
      }
      
      await controller.sendMessage(
        widget.chat.id,
        text,
        peerId: peerId,
      );
      
      _messageController.clear();
      
      // Scroll to bottom
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      // إظهار رسالة خطأ للمستخدم
      if (mounted) {
        final errorMessage = e.toString();
        final String userMessage;
        
        if (errorMessage.contains('Socket') || errorMessage.contains('غير متصل')) {
          userMessage = 'Socket غير متصل - تأكد من اتصال WiFi P2P بين الأجهزة';
        } else {
          userMessage = 'فشل إرسال الرسالة: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chat.id));

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              // Avatar مع Hero animation
              Hero(
                tag: 'chat_avatar_${widget.chat.id}',
                child: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Color(widget.chat.avatarColor),
                  child: Text(
                    _getInitial(widget.chat.name),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l10n.online,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
        children: [
          // قائمة الرسائل
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noMessages,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MessageBubble(message: message);
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    l10n.errorLoadingMessages,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16.sp,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // منطقة الإدخال - Floating Glass Pill
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(32.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      children: [
                        // زر Emoji (مؤقت)
                        IconButton(
                          icon: Icon(
                            Icons.emoji_emotions_outlined,
                            size: 24.sp,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // فتح لوحة Emoji
                            // سيتم تنفيذها لاحقاً عند إضافة مكتبة Emoji
                          },
                        ),
                        // حقل النص
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.typeMessage,
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        // زر الإرسال
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Colors.black,
                              size: 20.sp,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

