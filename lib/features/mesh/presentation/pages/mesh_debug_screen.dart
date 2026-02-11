import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/power_mode.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/utils/log_service.dart';

class MeshDebugScreen extends ConsumerStatefulWidget {
  const MeshDebugScreen({super.key});

  @override
  ConsumerState<MeshDebugScreen> createState() => _MeshDebugScreenState();
}

class _MeshDebugScreenState extends ConsumerState<MeshDebugScreen> {
  String _status = 'Unknown';
  int _peerCount = 0;
  PowerMode _currentPowerMode = PowerMode.balanced;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _listenToBackgroundService();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('power_mode');
    if (modeStr != null) {
      if (mounted) {
        setState(() {
          _currentPowerMode = PowerModeExtension.fromStorageString(modeStr);
        });
      }
    }
  }

  void _listenToBackgroundService() {
    FlutterBackgroundService().on('updateStatus').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _status = event['status'] ?? 'Unknown';
          _peerCount = event['peerCount'] ?? _peerCount;
        });
      }
    });

    FlutterBackgroundService().on('updatePeerCount').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _peerCount = event['count'] ?? _peerCount;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesh Debug & Power'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                theme,
                title: 'Background Service Status',
                content: _status,
                icon: Icons.notifications_active,
                color: _status.contains('Scanning') ? Colors.green : Colors.orange,
              ),
              SizedBox(height: 16.h),
              _buildInfoCard(
                theme,
                title: 'Connected Peers',
                content: '$_peerCount',
                icon: Icons.people,
                color: Colors.blue,
              ),
              SizedBox(height: 16.h),
              Text(
                'Power Mode Settings',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              _buildPowerModeSelector(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme,
      {required String title, required String content, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                Text(
                  content,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerModeSelector(ThemeData theme) {
    return Card(
      child: Column(
        children: PowerMode.values.map((mode) {
          return RadioListTile<PowerMode>(
            title: Text(mode.getDisplayNameAr()),
            subtitle: Text(mode.getDescriptionAr()),
            value: mode,
            groupValue: _currentPowerMode,
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _currentPowerMode = value;
                });
                // Update Prefs
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('power_mode', value.toStorageString());
                
                // Notify Background Service
                BackgroundService.instance.updatePowerMode(value);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
