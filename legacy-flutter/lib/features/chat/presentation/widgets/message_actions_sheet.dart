import 'package:flutter/material.dart';
import '../../domain/models/message_model.dart';

/// Bottom sheet لعرض خيارات الرسالة
class MessageActionsSheet extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  const MessageActionsSheet({
    super.key,
    required this.message,
    this.onCopy,
    this.onDelete,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Copy option
          if (onCopy != null)
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.blue),
              title: const Text('نسخ النص'),
              onTap: () {
                Navigator.pop(context);
                onCopy!();
              },
            ),

          // Retry option (only for failed messages)
          if (onRetry != null && message.status == MessageStatus.failed)
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: const Text('إعادة المحاولة'),
              onTap: () {
                Navigator.pop(context);
                onRetry!();
              },
            ),

          // Delete option
          if (onDelete != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف الرسالة'),
              onTap: () {
                Navigator.pop(context);
                onDelete!();
              },
            ),

          // Cancel
          const Divider(),
          ListTile(
            title: const Text(
              'إلغاء',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Helper function لعرض message actions sheet
void showMessageActions(
  BuildContext context, {
  required MessageModel message,
  VoidCallback? onCopy,
  VoidCallback? onDelete,
  VoidCallback? onRetry,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => MessageActionsSheet(
      message: message,
      onCopy: onCopy,
      onDelete: onDelete,
      onRetry: onRetry,
    ),
  );
}
