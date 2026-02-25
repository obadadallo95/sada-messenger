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
import '../../domain/models/message_model.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_recorder_button.dart';
import '../../../network/presentation/providers/network_state_provider.dart';

/// شاشة تفاصيل المحادثة
class ChatDetailsScreen extends ConsumerStatefulWidget {
  final ChatModel chat;

  const ChatDetailsScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends ConsumerState<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _currentPeerId; // cached for voice messages

  String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(0, 8);
  }

  Future<String?> _resolvePeerId() async {
    if (_currentPeerId != null) return _currentPeerId;
    if (!widget.chat.isGroup) {
      try {
        final database = await ref.read(appDatabaseProvider.future);
        final chatData = await database.getChatById(widget.chat.id);
        _currentPeerId = chatData?.peerId;
      } catch (_) {}
    }
    return _currentPeerId;
  }

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
      final controller = ref.read(chatControllerProvider.notifier);
      final peerId = await _resolvePeerId();
      await controller.sendMessage(widget.chat.id, text, peerId: peerId);
      _messageController.clear();
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('Socket') || e.toString().contains('غير متصل')
          ? 'Socket غير متصل - تأكد من اتصال WiFi P2P بين الأجهزة'
          : 'فشل إرسال الرسالة: ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  Future<void> _onVoiceRecorded(String filePath) async {
    try {
      final controller = ref.read(chatControllerProvider.notifier);
      final peerId = await _resolvePeerId();
      await controller.sendVoiceMessage(widget.chat.id, filePath, peerId: peerId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('فشل إرسال الرسالة الصوتية: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chat.id));
    final networkState = ref.watch(networkStateProvider);
    final chatId = _shortId(widget.chat.id);
    final subtitle = networkState.peerCount > 0
        ? 'ID: $chatId'
        : 'Offline Mesh Mode • ID: $chatId';

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
                  backgroundColor: Color(
                    widget.chat.avatarColor,
                  ), // Use real color
                  child: Text(
                    widget.chat.name.isNotEmpty
                        ? widget.chat.name[0].toUpperCase()
                        : '?',
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ],
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
                decoration: const BoxDecoration(color: Colors.transparent),
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
            // Delay Hint / Offline Warning
            if (messagesAsync.valueOrNull?.isNotEmpty == true &&
                messagesAsync.valueOrNull!.first.isMe &&
                messagesAsync.valueOrNull!.first.status ==
                    MessageStatus.sending)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  'قد يستغرق التسليم وقتاً لعدم توفر اتصال مباشر بالشبكة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // منطقة الإدخال - Floating Glass Pill
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                          // Voice recorder button
                          VoiceRecorderButton(onDone: _onVoiceRecorded),
                          SizedBox(width: 4.w),
                          // زر الإرسال
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
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
