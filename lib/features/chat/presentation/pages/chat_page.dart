import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../data/repositories/chat_repository.dart';
import '../widgets/chat_tile.dart';

/// شاشة الدردشة - قائمة المحادثات
class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chatsAsync = ref.watch(chatRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chat),
        centerTitle: true,
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.noChats,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatTile(
                chat: chat,
                onTap: () => context.push('${AppRoutes.chat}/${chat.id}', extra: chat),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.errorLoadingChats,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18.sp,
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

