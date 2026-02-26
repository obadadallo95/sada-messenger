import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/power_mode.dart';

/// Network status chip showing connection quality
class NetworkStatusChip extends StatelessWidget {
  final int peerCount;

  const NetworkStatusChip({
    super.key,
    required this.peerCount,
  });

  @override
  Widget build(BuildContext context) {
    final status = _getNetworkStatus(peerCount);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getStatusText(status);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14.sp,
            color: statusColor,
          ),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              if (peerCount > 0)
                Text(
                  '$peerCount جهاز متصل',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: statusColor.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  NetworkStatus _getNetworkStatus(int peerCount) {
    if (peerCount == 0) return NetworkStatus.offline;
    if (peerCount < 3) return NetworkStatus.weak;
    return NetworkStatus.active;
  }

  Color _getStatusColor(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.active:
        return Colors.green;
      case NetworkStatus.weak:
        return Colors.orange;
      case NetworkStatus.offline:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.active:
        return Icons.wifi;
      case NetworkStatus.weak:
        return Icons.wifi_2_bar;
      case NetworkStatus.offline:
        return Icons.wifi_off;
    }
  }

  String _getStatusText(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.active:
        return 'الشبكة: فعّالة';
      case NetworkStatus.weak:
        return 'الشبكة: ضعيفة';
      case NetworkStatus.offline:
        return 'الشبكة: متوقفة';
    }
  }
}

/// PowerMode indicator chip
class PowerModeChip extends StatelessWidget {
  final PowerMode mode;

  const PowerModeChip({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getModeColor(mode);
    final icon = _getModeIcon(mode);
    final text = mode.getDisplayNameAr();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(PowerMode mode) {
    switch (mode) {
      case PowerMode.highPerformance:
        return Colors.red;
      case PowerMode.balanced:
        return Colors.blue;
      case PowerMode.lowPower:
        return Colors.green;
    }
  }

  IconData _getModeIcon(PowerMode mode) {
    switch (mode) {
      case PowerMode.highPerformance:
        return Icons.bolt;
      case PowerMode.balanced:
        return Icons.balance;
      case PowerMode.lowPower:
        return Icons.battery_saver;
    }
  }
}

enum NetworkStatus {
  active,
  weak,
  offline,
}
