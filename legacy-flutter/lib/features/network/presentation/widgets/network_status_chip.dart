import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/network_state_provider.dart';

class NetworkStatusChip extends ConsumerWidget {
  const NetworkStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(networkStateProvider);

    final color = _getStatusColor(theme, state.peerCount, state.isScanning);
    final text = _getStatusText(state);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, int peerCount, bool isScanning) {
    if (peerCount > 0) return theme.colorScheme.tertiary;
    if (isScanning) return theme.colorScheme.secondary;
    return theme.colorScheme.outline;
  }

  String _getStatusText(NetworkState state) {
    if (state.peerCount > 0) return '${state.peerCount} متصل';
    if (state.isScanning) return 'جاري البحث...';
    if (state.status.toLowerCase().contains('sleep')) return 'وضع انتظار';
    return 'غير متصل';
  }
}
