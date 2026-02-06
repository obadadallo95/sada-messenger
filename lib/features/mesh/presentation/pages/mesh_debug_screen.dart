import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/network/mesh_channel.dart';
import '../../../../core/utils/log_service.dart';

/// Provider لـ MeshChannel
final meshChannelProvider = Provider<MeshChannel>((ref) => MeshChannel());

/// Provider لحالة Discovery
final discoveryStateProvider = StateProvider<bool>((ref) => false);

/// شاشة Debug لاكتشاف الأجهزة عبر WiFi P2P
class MeshDebugScreen extends ConsumerStatefulWidget {
  const MeshDebugScreen({super.key});

  @override
  ConsumerState<MeshDebugScreen> createState() => _MeshDebugScreenState();
}

class _MeshDebugScreenState extends ConsumerState<MeshDebugScreen> {
  final MeshChannel _meshChannel = MeshChannel();
  StreamSubscription<List<MeshPeer>>? _peersSubscription;
  StreamSubscription<ConnectionInfo>? _connectionSubscription;
  List<MeshPeer> _peers = [];
  ConnectionInfo? _connectionInfo;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // الاستماع لتحديثات الأجهزة
    _peersSubscription = _meshChannel.onPeersUpdated.listen(
      (peers) {
        if (mounted) {
          setState(() {
            _peers = peers;
            LogService.info('تم تحديث قائمة الأجهزة: ${peers.length} جهاز');
          });
        }
      },
      onError: (error) {
        LogService.error('خطأ في Stream الأجهزة', error);
        if (mounted) {
          setState(() {
            _errorMessage = 'خطأ في تحديثات الأجهزة: $error';
          });
        }
      },
    );

    // الاستماع لتحديثات الاتصال
    _connectionSubscription = _meshChannel.onConnectionInfo.listen(
      (connectionInfo) {
        if (mounted) {
          setState(() {
            _connectionInfo = connectionInfo;
            LogService.info('تم تحديث معلومات الاتصال');
          });
        }
      },
      onError: (error) {
        LogService.error('خطأ في Stream الاتصال', error);
      },
    );
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      if (await Permission.location.isDenied) Permission.location,
      if (await Permission.nearbyWifiDevices.isDenied) Permission.nearbyWifiDevices,
    ];

    if (permissions.isNotEmpty) {
      final statuses = await permissions.request();
      final allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب منح صلاحيات الموقع و WiFi للبحث عن الأجهزة'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // طلب الصلاحيات أولاً
    await _requestPermissions();

    final success = await _meshChannel.startDiscovery();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ref.read(discoveryStateProvider.notifier).state = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم بدء البحث عن الأجهزة'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'فشل بدء البحث عن الأجهزة';
        });
      }
    }
  }

  Future<void> _stopDiscovery() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _meshChannel.stopDiscovery();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ref.read(discoveryStateProvider.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إيقاف البحث عن الأجهزة'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _refreshPeers() async {
    setState(() {
      _isLoading = true;
    });

    final peers = await _meshChannel.getPeers();
    if (mounted) {
      setState(() {
        _peers = peers;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _peersSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDiscovering = ref.watch(discoveryStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesh Debug - WiFi P2P'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // أزرار التحكم
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading || isDiscovering ? null : _startDiscovery,
                    icon: const Icon(Icons.search),
                    label: const Text('بدء البحث'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading || !isDiscovering ? null : _stopDiscovery,
                    icon: const Icon(Icons.stop),
                    label: const Text('إيقاف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _refreshPeers,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث',
                  ),
                ],
              ),
            ),

            // حالة الاتصال
            if (_connectionInfo != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _connectionInfo!.isConnected
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _connectionInfo!.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: _connectionInfo!.isConnected ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _connectionInfo!.isConnected
                            ? 'متصل${_connectionInfo!.isGroupOwner ? " (Group Owner)" : ""}'
                            : 'غير متصل',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

            // رسالة خطأ
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading Indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),

            // عنوان القائمة
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Row(
                children: [
                  Text(
                    'الأجهزة المكتشفة (${_peers.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ],
              ),
            ),

            // قائمة الأجهزة
            Expanded(
              child: _peers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 64.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'لا توجد أجهزة مكتشفة',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'اضغط "بدء البحث" للبحث عن الأجهزة القريبة',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _peers.length,
                      itemBuilder: (context, index) {
                        final peer = _peers[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 8.h),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              child: Icon(
                                Icons.phone_android,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                            title: Text(
                              peer.deviceName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4.h),
                                Text(
                                  'MAC: ${peer.deviceAddress}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  'Status: ${_getStatusText(peer.status)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _getStatusColor(peer.status),
                                  ),
                                ),
                              ],
                            ),
                            trailing: peer.isServiceDiscoveryCapable
                                ? Icon(
                                    Icons.info_outline,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Available';
      case 1:
        return 'Invited';
      case 2:
        return 'Connected';
      case 3:
        return 'Failed';
      case 4:
        return 'Unavailable';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.red;
      case 4:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

