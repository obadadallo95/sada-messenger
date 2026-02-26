import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_dimensions.dart';
import 'package:sada/l10n/generated/app_localizations.dart';

/// شريط حالة الشبكة (Mesh Status Bar)
/// يعرض حالة الاتصال وعدد الأجهزة المتصلة
enum MeshStatus {
  connected,
  connecting,
  offline,
}

class MeshStatusBar extends StatelessWidget {
  final MeshStatus status;
  final int? peerCount;
  final String? connectionType; // "WiFi Direct" / "Bluetooth" / "Hybrid"

  const MeshStatusBar({
    super.key,
    required this.status,
    this.peerCount,
    this.connectionType,
  });

  Color _getStatusColor() {
    switch (status) {
      case MeshStatus.connected:
        return AppColors.success;
      case MeshStatus.connecting:
        return AppColors.warning;
      case MeshStatus.offline:
        return AppColors.error;
    }
  }

  String _getStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case MeshStatus.connected:
        return l10n?.home_status_connected ?? 'Connected';
      case MeshStatus.connecting:
        return l10n?.home_status_connecting ?? 'Connecting...';
      case MeshStatus.offline:
        return l10n?.home_status_offline ?? 'Offline';
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case MeshStatus.connected:
        return Icons.wifi;
      case MeshStatus.connecting:
        return Icons.wifi_find;
      case MeshStatus.offline:
        return Icons.wifi_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText(context);
    final statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.paddingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: AppDimensions.borderWidth,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 200;
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة الحالة
              Icon(
                statusIcon,
                size: AppDimensions.iconSizeSm,
                color: statusColor,
              ),
              SizedBox(width: AppDimensions.spacingSm),
              // نص الحالة
              Flexible(
                child: Text(
                  statusText,
                  style: AppTypography.labelMedium(context).copyWith(
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // عدد الأجهزة (إذا كان متوفراً)
              if (peerCount != null && peerCount! > 0 && !isSmallScreen) ...[
                SizedBox(width: AppDimensions.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    '$peerCount',
                    style: AppTypography.labelSmall(context).copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
              ],
              // نوع الاتصال (إذا كان متوفراً) - يظهر فقط على الشاشات الكبيرة
              if (connectionType != null && !isSmallScreen) ...[
                SizedBox(width: AppDimensions.spacingSm),
                Flexible(
                  child: Text(
                    connectionType!,
                    style: AppTypography.labelSmall(context).copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

