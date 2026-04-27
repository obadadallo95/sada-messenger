// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/mesh_service.dart';
import '../../../../core/utils/log_service.dart';
import '../../../../core/models/power_mode.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/services/metrics_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';

class MeshDebugScreen extends ConsumerStatefulWidget {
  const MeshDebugScreen({super.key});

  @override
  ConsumerState<MeshDebugScreen> createState() => _MeshDebugScreenState();
}

class _MeshDebugScreenState extends ConsumerState<MeshDebugScreen> {
  String _status = 'غير معروف';
  int _peerCount = 0;
  PowerMode _currentPowerMode = PowerMode.balanced;

  Timer? _refreshTimer;
  Map<String, dynamic> _relayMetrics = {};
  Map<String, int> _transportMetrics = {};
  Map<String, dynamic> _deliveryDiagnostics = {};
  List<String> _connectedPeers = [];
  StreamSubscription? _metricsSubscription;
  StreamSubscription? _peersSubscription;
  Map<String, dynamic> _bgDiagnostics = const {};
  String? _bgDiagnosticsError;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _listenToBackgroundService();
    _startMetricsRefresh();
    _runBackgroundDiagnostics();
    _runDeliveryDiagnostics();
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
    _metricsSubscription = metricsService.metricsStream.listen((metrics) {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('لم يتم العثور على ملف السجلات')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تسجيل السجلات غير مفعل')),
        );
      }
    }
  }

  String _buildDiagnosticsReport() {
    final lines = <String>[
      'تقرير تشخيص Sada - Mesh Debug',
      'حالة الخدمة: $_status',
      'عدد الأقران المتصلين: $_peerCount',
      'isConfigured: ${_bgDiagnostics['isConfigured'] ?? '-'}',
      'isRunning: ${_bgDiagnostics['isRunning'] ?? '-'}',
      'canStartMesh: ${_bgDiagnostics['canStartMesh'] ?? '-'}',
      'blockingReason: ${_bgDiagnostics['blockingReason'] ?? '-'}',
      'authType: ${_bgDiagnostics['authType'] ?? '-'}',
      'hasUserData: ${_bgDiagnostics['hasUserData'] ?? '-'}',
      'lastStage: ${_bgDiagnostics['lastStage'] ?? '-'}',
      'lastReason: ${_bgDiagnostics['lastReason'] ?? '-'}',
      'lastError: ${_bgDiagnostics['lastError'] ?? '-'}',
      'lastUpdatedAt: ${_bgDiagnostics['lastUpdatedAt'] ?? '-'}',
      'perm_locationWhenInUse: ${_bgDiagnostics['perm_locationWhenInUse'] ?? '-'}',
      'perm_bluetoothScan: ${_bgDiagnostics['perm_bluetoothScan'] ?? '-'}',
      'perm_bluetoothConnect: ${_bgDiagnostics['perm_bluetoothConnect'] ?? '-'}',
      'perm_bluetoothAdvertise: ${_bgDiagnostics['perm_bluetoothAdvertise'] ?? '-'}',
      'perm_nearbyWifiDevices: ${_bgDiagnostics['perm_nearbyWifiDevices'] ?? '-'}',
      'perm_ignoreBatteryOptimizations: ${_bgDiagnostics['perm_ignoreBatteryOptimizations'] ?? '-'}',
      'relay_totalCount: ${_relayMetrics['totalCount'] ?? 0}',
      'relay_highPriority: ${_relayMetrics['highPriority'] ?? 0}',
      'relay_standardPriority: ${_relayMetrics['standardPriority'] ?? 0}',
      'relay_lowPriority: ${_relayMetrics['lowPriority'] ?? 0}',
      'acks_sent: ${_transportMetrics['acksSent'] ?? 0}',
      'acks_received: ${_transportMetrics['acksReceived'] ?? 0}',
      'messages_delivered: ${_transportMetrics['messagesDelivered'] ?? 0}',
      'duplicates_ignored: ${_transportMetrics['duplicatesIgnored'] ?? 0}',
      'transport_socketConnected: ${(_deliveryDiagnostics['transport']?['socketConnected']) ?? '-'}',
      'transport_readyPeers: ${(_deliveryDiagnostics['transport']?['readyPeers']) ?? '-'}',
      'transport_peerStates: ${(_deliveryDiagnostics['transport']?['peerStates']) ?? '-'}',
      'transport_knownPeerIps: ${(_deliveryDiagnostics['transport']?['knownPeerIps']) ?? '-'}',
      'transport_blockerHint: ${(_deliveryDiagnostics['transport']?['blockerHint']) ?? '-'}',
      'transport_lastError: ${(_deliveryDiagnostics['transport']?['lastTransportError']) ?? '-'}',
      'transport_handshakeAttempts: ${(_deliveryDiagnostics['transport']?['handshakeAttempts']) ?? '-'}',
      'transport_handshakeAcks: ${(_deliveryDiagnostics['transport']?['handshakeAcks']) ?? '-'}',
      'transport_handshakeTimeouts: ${(_deliveryDiagnostics['transport']?['handshakeTimeouts']) ?? '-'}',
      'transport_lastSocketRemoteIp: ${(_deliveryDiagnostics['transport']?['lastSocketRemoteIp']) ?? '-'}',
      'udp_running: ${(_deliveryDiagnostics['transport']?['udp']?['running']) ?? '-'}',
      'udp_deviceId: ${(_deliveryDiagnostics['transport']?['udp']?['deviceId']) ?? '-'}',
      'udp_sentCount: ${(_deliveryDiagnostics['transport']?['udp']?['sentCount']) ?? '-'}',
      'udp_receivedCount: ${(_deliveryDiagnostics['transport']?['udp']?['receivedCount']) ?? '-'}',
      'udp_lastSentAt: ${(_deliveryDiagnostics['transport']?['udp']?['lastSentAt']) ?? '-'}',
      'udp_lastReceivedAt: ${(_deliveryDiagnostics['transport']?['udp']?['lastReceivedAt']) ?? '-'}',
      'udp_lastFromIp: ${(_deliveryDiagnostics['transport']?['udp']?['lastFromIp']) ?? '-'}',
      'udp_lastError: ${(_deliveryDiagnostics['transport']?['udp']?['lastError']) ?? '-'}',
      'db_statusCounts: ${(_deliveryDiagnostics['database']?['statusCounts']) ?? '-'}',
      'db_retryBacklog: ${(_deliveryDiagnostics['database']?['retryBacklog']) ?? '-'}',
      'db_recentFailedMessageIds: ${(_deliveryDiagnostics['database']?['recentFailedMessageIds']) ?? '-'}',
    ];
    return lines.join('\n');
  }

  Future<void> _copyDiagnosticsReport() async {
    final report = _buildDiagnosticsReport();
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ تقرير التشخيص')),
    );
  }

  Future<void> _restartBackgroundService() async {
    final ok = await BackgroundService.instance.restart();
    await _runBackgroundDiagnostics();
    await _runDeliveryDiagnostics();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تمت محاولة إعادة تشغيل الخدمة' : 'فشلت إعادة تشغيل الخدمة'),
      ),
    );
  }

  Future<void> _refreshMetrics() async {
    if (!mounted) return;
    try {
      final AppDatabase database = await ref.read(appDatabaseProvider.future);
      final metrics = await database.getRelayQueueMetrics();
      if (mounted) {
        setState(() {
          _relayMetrics = metrics;
        });
      }
    } catch (e) {
      LogService.error('خطأ في تحديث metrics', e);
    }
  }

  Future<void> _runBackgroundDiagnostics() async {
    try {
      final report = await BackgroundService.instance.diagnose();
      final permissionReport = await _collectPermissionDiagnostics();
      if (!mounted) return;
      setState(() {
        _bgDiagnostics = {
          ...report,
          ...permissionReport,
        };
        _bgDiagnosticsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bgDiagnosticsError = e.toString();
      });
    }
  }

  Future<void> _runDeliveryDiagnostics() async {
    try {
      final meshService = ref.read(meshServiceProvider);
      final transportDiag = await meshService.getTransportDiagnostics();
      final AppDatabase database = await ref.read(appDatabaseProvider.future);
      final dbDiag = await database.getMessageDeliveryDiagnostics();
      if (!mounted) return;
      setState(() {
        _deliveryDiagnostics = {
          'transport': transportDiag,
          'database': dbDiag,
        };
      });
    } catch (e) {
      LogService.error('خطأ في تشخيص إرسال الرسائل', e);
    }
  }

  Future<Map<String, dynamic>> _collectPermissionDiagnostics() async {
    final permissions = <Permission, String>{
      Permission.locationWhenInUse: 'locationWhenInUse',
      Permission.bluetoothScan: 'bluetoothScan',
      Permission.bluetoothConnect: 'bluetoothConnect',
      Permission.bluetoothAdvertise: 'bluetoothAdvertise',
      Permission.nearbyWifiDevices: 'nearbyWifiDevices',
      Permission.ignoreBatteryOptimizations: 'ignoreBatteryOptimizations',
    };

    final result = <String, dynamic>{};
    for (final entry in permissions.entries) {
      final status = await entry.key.status;
      result['perm_${entry.value}'] = status.name;
    }
    return result;
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
    FlutterBackgroundService().isRunning().then((running) {
      if (!mounted) return;
      if (running && _status == 'غير معروف') {
        setState(() {
          _status = 'تعمل (بانتظار تحديث الحالة)';
        });
      }
    });

    FlutterBackgroundService().on('updateStatus').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _status = event['status'] ?? 'غير معروف';
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
        title: const Text('تشخيص الشبكة والطاقة'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: () async {
              await _runBackgroundDiagnostics();
              await _runDeliveryDiagnostics();
            },
            tooltip: 'تشغيل التشخيص',
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copyDiagnosticsReport,
            tooltip: 'نسخ التقرير',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLogFile,
            tooltip: 'مشاركة السجلات',
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
                title: 'حالة الخدمة الخلفية',
                content: _status,
                icon: Icons.notifications_active,
                color: _status.contains('Scanning')
                    ? Colors.green
                    : Colors.orange,
              ),
              SizedBox(height: 16.h),
              _buildBackgroundDiagnosticsCard(theme),
              SizedBox(height: 16.h),
              _buildDeliveryDiagnosticsCard(theme),
              SizedBox(height: 16.h),
              _buildInfoCard(
                theme,
                title: 'الأجهزة المتصلة',
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
                      children: _connectedPeers
                          .map(
                            (p) => Text(
                              p,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontFamily: 'monospace',
                              ),
                            ),
                          )
                          .toList(),
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
                'إعدادات وضع الطاقة',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              _buildPowerModeSelector(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDiagnosticsCard(ThemeData theme) {
    final canStartMesh = _bgDiagnostics['canStartMesh'] == true;
    final isRunning = _bgDiagnostics['isRunning'] == true;
    final blockingReason = (_bgDiagnostics['blockingReason'] ?? '').toString();

    final statusText = _bgDiagnosticsError != null
        ? 'فشل التشخيص'
        : canStartMesh
        ? (isRunning ? 'سليمة' : 'يمكن البدء لكنها لا تعمل')
        : 'محجوبة';

    final color = _bgDiagnosticsError != null
        ? theme.colorScheme.error
        : canStartMesh
        ? (isRunning ? Colors.green : Colors.orange)
        : theme.colorScheme.error;

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
                Icon(Icons.health_and_safety, color: color),
                SizedBox(width: 8.w),
                Text(
                  'تشخيص قناة الخدمة الخلفية',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              'الحالة: $statusText',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await _runBackgroundDiagnostics();
                    await _runDeliveryDiagnostics();
                  },
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('تحديث كامل'),
                ),
                ElevatedButton.icon(
                  onPressed: _restartBackgroundService,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('إعادة تشغيل الخدمة'),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            if (_bgDiagnosticsError != null)
              Text(
                _bgDiagnosticsError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            if (blockingReason.isNotEmpty)
              Text(
                'السبب: $blockingReason',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            SizedBox(height: 8.h),
            Text(
              'authType: ${_bgDiagnostics['authType'] ?? '-'} • hasUserData: ${_bgDiagnostics['hasUserData'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'isConfigured: ${_bgDiagnostics['isConfigured'] ?? '-'} • isRunning: ${_bgDiagnostics['isRunning'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'effectiveStatus: ${_bgDiagnostics['effectiveStatus'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 8.h),
            Text(
              'آخر مرحلة: ${_bgDiagnostics['lastStage'] ?? '-'}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'آخر سبب: ${_bgDiagnostics['lastReason'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            if ((_bgDiagnostics['lastError'] ?? '').toString().isNotEmpty)
              Text(
                'آخر خطأ: ${_bgDiagnostics['lastError']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            Text(
              'آخر تحديث: ${_bgDiagnostics['lastUpdatedAt'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 8.h),
            Text(
              'الصلاحيات',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'الموقع: ${_bgDiagnostics['perm_locationWhenInUse'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'بلوتوث (فحص/اتصال/إعلان): '
              '${_bgDiagnostics['perm_bluetoothScan'] ?? '-'} / '
              '${_bgDiagnostics['perm_bluetoothConnect'] ?? '-'} / '
              '${_bgDiagnostics['perm_bluetoothAdvertise'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'WiFi قريب: ${_bgDiagnostics['perm_nearbyWifiDevices'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'تجاهل تحسين البطارية: ${_bgDiagnostics['perm_ignoreBatteryOptimizations'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
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
                  'مؤشرات طابور الترحيل',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'استخدام التخزين: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} / ${(limitBytes / 1024 / 1024).toStringAsFixed(0)} MB',
            ),
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
                _buildMetricItem(
                  'الإجمالي',
                  '${_relayMetrics['totalCount'] ?? 0}',
                ),
                _buildMetricItem(
                  'عالي',
                  '${_relayMetrics['highPriority'] ?? 0}',
                  color: Colors.red,
                ),
                _buildMetricItem(
                  'متوسط',
                  '${_relayMetrics['standardPriority'] ?? 0}',
                  color: Colors.blue,
                ),
                _buildMetricItem(
                  'منخفض',
                  '${_relayMetrics['lowPriority'] ?? 0}',
                  color: Colors.grey,
                ),
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
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    final normalizedTitle = title.trim().isEmpty ? 'الحالة' : title;
    final normalizedContent = content.trim().isEmpty ? 'غير معروف' : content;

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
                  normalizedTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  normalizedContent,
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
                const Icon(
                  Icons.compare_arrows_rounded,
                  color: Colors.blueAccent,
                ),
                SizedBox(width: 8.w),
                Text(
                  'مؤشرات النقل (ACKs)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  'مرسل',
                  '${_transportMetrics['acksSent'] ?? 0}',
                  color: Colors.blue,
                ),
                _buildMetricItem(
                  'مستلم',
                  '${_transportMetrics['acksReceived'] ?? 0}',
                  color: Colors.green,
                ),
                _buildMetricItem(
                  'تم التسليم',
                  '${_transportMetrics['messagesDelivered'] ?? 0}',
                  color: Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Center(
              child: Text(
                'التكرارات المتجاهلة: ${_transportMetrics['duplicatesIgnored'] ?? 0}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDiagnosticsCard(ThemeData theme) {
    final transport = (_deliveryDiagnostics['transport'] as Map?) ?? const {};
    final udp = (transport['udp'] as Map?) ?? const {};
    final database = (_deliveryDiagnostics['database'] as Map?) ?? const {};
    final statusCounts = (database['statusCounts'] as Map?) ?? const {};

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
                Icon(Icons.fact_check_outlined, color: theme.colorScheme.primary),
                SizedBox(width: 8.w),
                Text(
                  'تشخيص فشل الإرسال',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              'Socket متصل: ${transport['socketConnected'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Peer_Ready: ${transport['readyPeers'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'حالات الأقران: ${transport['peerStates'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'خرائط IP->Peer: ${transport['knownPeerIps'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'سبب التعطّل: ${transport['blockerHint'] ?? '-'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'آخر خطأ نقل: ${transport['lastTransportError'] ?? '-'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            Text(
              'Handshake attempts=${transport['handshakeAttempts'] ?? '-'} ack=${transport['handshakeAcks'] ?? '-'} timeouts=${transport['handshakeTimeouts'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Socket remote ip: ${transport['lastSocketRemoteIp'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 8.h),
            Text(
              'UDP: running=${udp['running'] ?? '-'} sent=${udp['sentCount'] ?? '-'} received=${udp['receivedCount'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'UDP lastRx=${udp['lastReceivedAt'] ?? '-'} from=${udp['lastFromIp'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'UDP lastError=${udp['lastError'] ?? '-'}',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 8.h),
            Text(
              'حالات الرسائل: sending=${statusCounts['sending'] ?? 0}, sent=${statusCounts['sent'] ?? 0}, delivered=${statusCounts['delivered'] ?? 0}, failed=${statusCounts['failed'] ?? 0}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Retry backlog: ${database['retryBacklog'] ?? 0}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'آخر رسائل فاشلة: ${database['recentFailedMessageIds'] ?? []}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
