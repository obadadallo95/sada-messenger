import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/mesh_service.dart';
import '../../../../core/utils/log_service.dart';
import '../../../../core/models/power_mode.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/services/metrics_service.dart';

class MeshDebugScreen extends ConsumerStatefulWidget {
  const MeshDebugScreen({super.key});

  @override
  ConsumerState<MeshDebugScreen> createState() => _MeshDebugScreenState();
}

class _MeshDebugScreenState extends ConsumerState<MeshDebugScreen> {
  String _status = 'Unknown';
  int _peerCount = 0;
  PowerMode _currentPowerMode = PowerMode.balanced;

  Timer? _refreshTimer;
  Map<String, dynamic> _relayMetrics = {};
  Map<String, int> _transportMetrics = {};
  List<String> _connectedPeers = [];
  StreamSubscription? _metricsSubscription;
  StreamSubscription? _peersSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _listenToBackgroundService();
    _startMetricsRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _metricsSubscription?.cancel();
    _peersSubscription?.cancel();
    super.dispose();
  }

  void _startMetricsRefresh() {
    _refreshMetrics();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshMetrics();
    });
    
    // Listen to transport metrics
    final metricsService = ref.read(metricsServiceProvider);
    _transportMetrics = metricsService.currentMetrics;
      if (mounted) {
        setState(() {
          _transportMetrics = metrics;
        });
      }
    });

    // Listen to connected peers
    final meshService = ref.read(meshServiceProvider);
    _connectedPeers = meshService.connectedPeers;
    _peersSubscription = meshService.connectedPeersStream.listen((peers) {
      if (mounted) {
        setState(() {
          _connectedPeers = peers;
          _peerCount = peers.length;
        });
      }
    });
  }

  Future<void> _shareLogFile() async {
    final path = LogService.currentLogFilePath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(path)], text: 'Sada Debug Logs');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log file not found')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log file logging not enabled')),
        );
      }
    }
  }

  Future<void> _refreshMetrics() async {
    if (!mounted) return;
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final metrics = await database.getRelayQueueMetrics();
      if (mounted) {
        setState(() {
          _relayMetrics = metrics;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing metrics: $e');
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLogFile,
            tooltip: 'Share Logs',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              if (_connectedPeers.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _connectedPeers.map((p) => Text(
                        p, 
                        style: TextStyle(fontSize: 10.sp, fontFamily: 'monospace')
                      )).toList(),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              _buildRelayQueueMetrics(theme),
              SizedBox(height: 16.h),
              _buildTransportMetrics(theme),
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

  Widget _buildRelayQueueMetrics(ThemeData theme) {
    final totalBytes = _relayMetrics['totalBytes'] ?? 0;
    final limitBytes = _relayMetrics['limitBytes'] ?? 1;
    final usagePercent = (totalBytes / limitBytes).clamp(0.0, 1.0);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_rounded, color: Colors.purple),
                SizedBox(width: 8.w),
                Text(
                  'Relay Queue Metrics',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text('Storage Usage: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} / ${(limitBytes / 1024 / 1024).toStringAsFixed(0)} MB'),
            SizedBox(height: 4.h),
            LinearProgressIndicator(
              value: usagePercent,
              backgroundColor: Colors.grey[200],
              color: usagePercent > 0.9 ? Colors.red : Colors.purple,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('Total', '${_relayMetrics['totalCount'] ?? 0}'),
                _buildMetricItem('High', '${_relayMetrics['highPriority'] ?? 0}', color: Colors.red),
                _buildMetricItem('Std', '${_relayMetrics['standardPriority'] ?? 0}', color: Colors.blue),
                _buildMetricItem('Low', '${_relayMetrics['lowPriority'] ?? 0}', color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: color)),
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
      ],
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

  Widget _buildTransportMetrics(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows_rounded, color: Colors.blueAccent),
                SizedBox(width: 8.w),
                Text(
                  'Transport Metrics (ACKs)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                 _buildMetricItem('Sent', '${_transportMetrics['acksSent'] ?? 0}', color: Colors.blue),
                 _buildMetricItem('Rcvd', '${_transportMetrics['acksReceived'] ?? 0}', color: Colors.green),
                 _buildMetricItem('Dlvr', '${_transportMetrics['messagesDelivered'] ?? 0}', color: Colors.orange),
              ],
            ),
            SizedBox(height: 8.h),
            Center(
              child: Text(
                'Dupes Ignored: ${_transportMetrics['duplicatesIgnored'] ?? 0}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
