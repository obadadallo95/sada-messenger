import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class NetworkStatusChip extends StatefulWidget {
  const NetworkStatusChip({super.key});

  @override
  State<NetworkStatusChip> createState() => _NetworkStatusChipState();
}

class _NetworkStatusChipState extends State<NetworkStatusChip> {
  int _peerCount = 0;
  String _status = 'Initializing...';
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _listenToService();
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
          _isScanning = (_status.contains('Scanning'));
          if (event['peerCount'] != null) {
            _peerCount = event['peerCount'];
          }
        });
      }
    });
  }

  Color _getStatusColor() {
    if (_peerCount > 0) return Colors.green;
    if (_isScanning) return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText() {
    if (_peerCount > 0) return '$_peerCount متصل';
    if (_isScanning) return 'جاري البحث...';
    return 'غير متصل';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor();

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
            _getStatusText(),
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
}
