import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/power_mode.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/widgets/mesh_gradient_background.dart';

class NetworkDashboardScreen extends StatefulWidget {
  const NetworkDashboardScreen({super.key});

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen> {
  int _peerCount = 0;
  String _status = 'Initializing...';
  PowerMode _currentPowerMode = PowerMode.balanced;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _listenToService();
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

  void _listenToService() {
    FlutterBackgroundService().on('updatePeerCount').listen((event) {
      if (mounted && event != null) {
        setState(() {
          _peerCount = event['count'] ?? 0;
        });
      }
    });

    FlutterBackgroundService().on('updateStatus').listen((event) {
      if (mounted && event != null) {
        setState(() {
          _status = event['status'] ?? '';
          if (event['peerCount'] != null) {
            _peerCount = event['peerCount'];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              _buildNetworkHealthCard(theme),
              SizedBox(height: 16.h),
              _buildStatsGrid(theme),
              SizedBox(height: 24.h),
              Text(
                'وضع الطاقة والشبكة',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
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

  Widget _buildNetworkHealthCard(ThemeData theme) {
    Color healthColor;
    String healthText;
    IconData healthIcon;

    if (_peerCount > 2) {
      healthColor = Colors.greenAccent;
      healthText = 'ممتازة';
      healthIcon = Icons.wifi_tethering;
    } else if (_peerCount > 0) {
      healthColor = Colors.blueAccent;
      healthText = 'جيدة';
      healthIcon = Icons.wifi;
    } else {
      healthColor = Colors.orangeAccent;
      healthText = 'بحث...';
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
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _status,
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

  Widget _buildStatsGrid(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            title: 'المتصلين',
            value: '$_peerCount',
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
            color: Colors.amberAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme,
      {required String title,
      required String value,
      required String unit,
      required IconData icon,
      required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
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
                     // Update Prefs
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('power_mode', mode.toStorageString());
                    
                    // Notify Background Service
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
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Radio<PowerMode>(
                          value: mode,
                          groupValue: _currentPowerMode,
                          onChanged: null, // Handled by InkWell
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                mode.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
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
