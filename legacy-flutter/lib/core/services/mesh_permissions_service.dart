import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../utils/log_service.dart';

/// Runtime permission gate for mesh discovery/transport on Android.
class MeshPermissionsService {
  Future<bool> ensureMeshPermissions() async {
    if (!Platform.isAndroid) return true;

    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    try {
      final statuses = await permissions.request();

      bool allGranted = true;
      for (final permission in permissions) {
        final status = statuses[permission] ?? PermissionStatus.denied;
        final granted = status.isGranted || status.isLimited;
        if (!granted) {
          allGranted = false;
          LogService.warning(
            'صلاحية Mesh مرفوضة: $permission (status: $status)',
          );
        }
      }

      if (allGranted) {
        LogService.info('تم منح جميع صلاحيات Mesh المطلوبة');
      } else {
        LogService.warning('لم يتم منح جميع صلاحيات Mesh المطلوبة');
      }

      return allGranted;
    } catch (e) {
      LogService.error('خطأ أثناء طلب صلاحيات Mesh', e);
      return false;
    }
  }
}
