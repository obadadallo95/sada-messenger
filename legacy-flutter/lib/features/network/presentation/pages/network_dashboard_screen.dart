// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/power_mode.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/widgets/mesh_gradient_background.dart';
import '../providers/network_state_provider.dart';
import '../providers/relay_queue_provider.dart';

class NetworkDashboardScreen extends ConsumerStatefulWidget {
  const NetworkDashboardScreen({super.key});

  @override
  ConsumerState<NetworkDashboardScreen> createState() =>
      _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState
    extends ConsumerState<NetworkDashboardScreen> {
  PowerMode _currentPowerMode = PowerMode.balanced;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('power_mode');
    if (modeStr != null && mounted) {
      setState(() {
        _currentPowerMode = PowerModeExtension.fromStorageString(modeStr);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final networkState = ref.watch(networkStateProvider);
    final relayCountAsync = ref.watch(relayQueueCountProvider);
    final relayCount = relayCountAsync.valueOrNull ?? 0;

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'مركز الشبكة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary,
            ),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNetworkHealthCard(theme, networkState),
              SizedBox(height: 16.h),
              _buildStatsGrid(theme, networkState),
              SizedBox(height: 12.h),
              _buildRelayTransparencyCard(
                theme,
                relayCount: relayCount,
                isLoading: relayCountAsync.isLoading,
              ),
              SizedBox(height: 24.h),
              Text(
                'وضع الطاقة والشبكة',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              _buildPowerModeSelector(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelayTransparencyCard(
    ThemeData theme, {
    required int relayCount,
    required bool isLoading,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: theme.colorScheme.primary,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              isLoading
                  ? 'جارٍ تحديث عدد الحزم المشفرة...'
                  : '📦 تحمل الآن $relayCount حزمة مشفرة لصالح الشبكة',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkHealthCard(ThemeData theme, NetworkState networkState) {
    Color healthColor;
    String healthText;
    IconData healthIcon;

    if (networkState.peerCount > 2) {
      healthColor = theme.colorScheme.tertiary;
      healthText = 'ممتازة';
      healthIcon = Icons.wifi_tethering;
    } else if (networkState.peerCount > 0) {
      healthColor = theme.colorScheme.primary;
      healthText = 'جيدة';
      healthIcon = Icons.wifi;
    } else if (networkState.isScanning) {
      healthColor = theme.colorScheme.secondary;
      healthText = 'بحث...';
      healthIcon = Icons.radar;
    } else {
      healthColor = theme.colorScheme.outline;
      healthText = 'غير متصلة';
      healthIcon = Icons.signal_wifi_statusbar_connected_no_internet_4;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.3),
            border: Border.all(color: healthColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: healthColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(healthIcon, size: 48.sp, color: healthColor),
              SizedBox(height: 12.h),
              Text(
                healthText,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: healthColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'حالة الشبكة الحالية',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  networkState.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: healthColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, NetworkState networkState) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            title: 'المتصلين',
            value: '${networkState.peerCount}',
            unit: 'جهاز',
            icon: Icons.group_work,
            color: theme.colorScheme.secondary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            theme,
            title: 'وضع الطاقة',
            value: _currentPowerMode.displayName.split(' ').first,
            unit: '',
            icon: Icons.bolt,
            color: theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.2),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24.sp),
              SizedBox(height: 12.h),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerModeSelector(ThemeData theme) {
    return Column(
      children: PowerMode.values.map((mode) {
        final isSelected = _currentPowerMode == mode;
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    setState(() {
                      _currentPowerMode = mode;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('power_mode', mode.toStorageString());
                    BackgroundService.instance.updatePowerMode(mode);
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.surface.withValues(alpha: 0.1),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Radio<PowerMode>(
                          value: mode,
                          groupValue: _currentPowerMode,
                          onChanged: null,
                          activeColor: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                mode.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
