import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/security/security_providers.dart';
import '../../../../core/security/key_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/glass_card.dart';
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
        backgroundColor: Colors.transparent,
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
          
          // اختصار User ID للعرض
          final userId = currentUser?.userId ?? '';
          final shortId = userId.length > 8 
              ? '${userId.substring(0, 4)}...${userId.substring(userId.length - 4)}'
              : userId;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxHeight < 700;
              final qrSize = isSmallScreen 
                  ? AppDimensions.qrCodeSize * 0.7
                  : AppDimensions.qrCodeSize;
              
              return SingleChildScrollView(
                padding: EdgeInsets.all(AppDimensions.paddingLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: AppDimensions.spacingLg),
                    
                    // بطاقة QR Code
                    GlassCard(
                      padding: EdgeInsets.all(
                        isSmallScreen ? AppDimensions.paddingMd : AppDimensions.paddingLg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // QR Code
                          Container(
                            padding: EdgeInsets.all(AppDimensions.paddingMd),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            ),
                            child: QrImageView(
                              data: qrJson,
                              version: QrVersions.auto,
                              size: qrSize,
                              backgroundColor: Colors.white,
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.primary,
                              ),
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.primary,
                              ),
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                          ),
                      
                      SizedBox(height: AppDimensions.spacingLg),
                      
                      // اسم المستخدم
                      Text(
                        currentUser?.displayName ?? 'Unknown',
                        style: AppTypography.titleLarge(context),
                      ),
                      
                      SizedBox(height: AppDimensions.spacingSm),
                      
                      // User ID مع زر نسخ
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '${l10n.userId}: ',
                              style: AppTypography.bodyMedium(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              shortId,
                              style: AppTypography.bodyMedium(context).copyWith(
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppDimensions.spacingSm),
                          IconButton(
                            icon: Icon(Icons.copy, size: AppDimensions.iconSizeSm),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: userId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم النسخ'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'نسخ المعرف',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppDimensions.spacingXl),
                
                // فاصل "أو"
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
                      child: Text(
                        'أو',
                        style: AppTypography.labelMedium(context),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                
                SizedBox(height: AppDimensions.spacingLg),
                
                // عنوان مشاركة
                Text(
                  'مشاركة عبر',
                  style: AppTypography.titleMedium(context),
                ),
                
                SizedBox(height: AppDimensions.spacingMd),
                
                // أزرار المشاركة
                Wrap(
                  spacing: AppDimensions.spacingMd,
                  runSpacing: AppDimensions.spacingMd,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildShareButton(
                      context,
                      icon: Icons.share,
                      label: l10n.share,
                      onTap: () => _shareQrCode(context, qrJson, ref),
                    ),
                  ],
                ),
                
                SizedBox(height: AppDimensions.spacingXl),
                
                    // نص توضيحي
                    Text(
                      l10n.shareQrCodeDescription,
                      style: AppTypography.bodySmall(context),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
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
  Future<void> _shareQrCode(BuildContext context, String qrJson, WidgetRef ref) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final authService = ref.read(authServiceProvider.notifier);
      final currentUser = authService.currentUser;
      
      // اختصار User ID للعرض
      final userId = currentUser?.userId ?? '';
      final shortId = userId.length > 8 
          ? '${userId.substring(0, 4)}...${userId.substring(userId.length - 4)}'
          : userId;
      
      // رسالة مشاركة مقروءة بدون JSON خام
      final shareMessage = l10n.localeName == 'ar'
          ? 'دعنا نتحدث على ${l10n.appName}! أضفني باستخدام معرفي: $shortId\n\n(امسح رمز QR هذا في التطبيق)'
          : "Let's chat on ${l10n.appName}! Add me using my ID: $shortId\n\n(Scan this QR code in the app)";
      
      // ignore: deprecated_member_use
      await Share.share(shareMessage);
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

  /// بناء زر مشاركة
  Widget _buildShareButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: AppDimensions.iconSizeSm),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
      ),
    );
  }
}


