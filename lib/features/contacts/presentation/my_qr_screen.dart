import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/security/security_providers.dart';
import '../../../../core/security/key_manager.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../../core/utils/log_service.dart';

/// شاشة عرض QR Code للمستخدم
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authService = ref.watch(authServiceProvider.notifier);
    final keyManager = ref.watch(keyManagerProvider);
    
    final currentUser = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myQrCode),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _generateQrData(currentUser, keyManager),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.sp,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'خطأ في تحميل QR Code',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          final qrData = snapshot.data!;
          final qrJson = jsonEncode(qrData);
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                SizedBox(height: 32.h),
                // QR Code Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        // QR Code
                        QrImageView(
                          data: qrJson,
                          version: QrVersions.auto,
                          size: 280.w,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                        SizedBox(height: 24.h),
                        // User Info
                        Text(
                          currentUser?.displayName ?? 'Unknown',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l10n.shareQrCodeDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                // Share Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareQrCode(context, qrJson),
                    icon: Icon(Icons.share, size: 20.sp),
                    label: Text(l10n.share),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Info Text
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20.sp,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                      child: Text(
                        l10n.qrCodeSecurityInfo,
                        style: theme.textTheme.bodySmall,
                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// توليد بيانات QR Code
  Future<Map<String, dynamic>> _generateQrData(
    UserData? currentUser,
    KeyManager keyManager,
  ) async {
    try {
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // الحصول على Public Key
      final publicKeyBytes = await keyManager.getPublicKey();
      final publicKeyBase64 = base64Encode(publicKeyBytes);
      
      // إنشاء payload
      final qrData = {
        'id': currentUser.userId,
        'name': currentUser.displayName,
        'publicKey': publicKeyBase64,
      // avatar يمكن إضافته لاحقاً إذا كان متوفراً
      // if (currentUser.avatarBase64 != null) {
      //   qrData['avatar'] = currentUser.avatarBase64;
      // }
      };
      
      LogService.info('تم توليد QR Code بنجاح');
      return qrData;
    } catch (e) {
      LogService.error('خطأ في توليد QR Code', e);
      rethrow;
    }
  }

  /// مشاركة QR Code
  Future<void> _shareQrCode(BuildContext context, String qrJson) async {
    try {
      // ignore: deprecated_member_use
      await Share.share(
        'Scan this QR code to add me on Sada:\n\n$qrJson',
      );
    } catch (e) {
      LogService.error('خطأ في مشاركة QR Code', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل مشاركة QR Code'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

