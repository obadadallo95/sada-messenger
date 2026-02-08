import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/log_service.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/services/auth_service.dart';
import '../../../../features/chat/domain/models/chat_model.dart';
import '../../../../core/network/mesh_service.dart';
import '../../../../core/network/models/mesh_message.dart';

/// شاشة مسح QR Code لإضافة جهة اتصال
class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key});

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// طلب صلاحية الكاميرا
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (!_hasPermission) {
      LogService.warning('تم رفض صلاحية الكاميرا');
    }
  }

  /// معالجة QR Code المكتشف
  Future<void> _handleQrCode(String? rawValue) async {
    if (rawValue == null || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      LogService.info('تم اكتشاف QR Code: ${rawValue.substring(0, rawValue.length > 50 ? 50 : rawValue.length)}...');
      
      // تحليل JSON
      Map<String, dynamic> qrData;
      try {
        qrData = jsonDecode(rawValue);
      } catch (e) {
        LogService.error('QR Code غير صحيح - ليس JSON', e);
        _showError('Invalid QR Code format');
        return;
      }
      
      // التحقق من الحقول المطلوبة
      final String? contactId = qrData['id'] as String?;
      final String? name = qrData['name'] as String?;
      final String? publicKey = qrData['publicKey'] as String?;
      
      if (contactId == null || publicKey == null) {
        LogService.error('QR Code ناقص - id أو publicKey مفقود');
        _showError('Invalid QR Code: Missing required fields');
        return;
      }
      
      // التحقق من أن المستخدم لا يضيف نفسه
      final authService = ref.read(authServiceProvider.notifier);
      final currentUser = authService.currentUser;
      if (currentUser?.userId == contactId) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showError(l10n.cannotAddYourself);
        }
        return;
      }
      
      // التحقق من أن جهة الاتصال غير موجودة بالفعل
      final database = await ref.read(appDatabaseProvider.future);
      final existingContact = await database.getContactById(contactId);
      
      if (existingContact != null) {
        // جهة الاتصال موجودة - الانتقال إلى المحادثة
        LogService.info('جهة الاتصال موجودة بالفعل: $contactId');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.contactAlreadyExists),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          );
        }
        await _navigateToChat(contactId, database);
        return;
      }
      
      // إضافة جهة الاتصال إلى قاعدة البيانات
      await database.insertContact(
        ContactsTableCompanion.insert(
          id: contactId,
          name: name ?? 'Unknown',
          publicKey: Value(publicKey),
          avatar: const Value.absent(), // يمكن إضافة avatar لاحقاً
          isBlocked: const Value(false),
        ),
      );
      
      
      LogService.info('تم إضافة جهة الاتصال بنجاح: $contactId');

      // ==================== MUTUAL CONTACT EXCHANGE ====================
      // إرسال معلوماتي للطرف الآخر (ليضيفني تلقائياً)
      try {
        if (currentUser != null) {
          final myProfile = {
            'id': currentUser.userId,
            'name': currentUser.displayName,
            'publicKey': currentUser.publicKey, 
            // Avatar can be added here if available as base64
          };

          final meshService = ref.read(meshServiceProvider);
          
          // إرسال رسالة Contact Exchange
          // نرسل البيانات كـ JSON String في encryptedContent (مشفرة أو واضحة حسب التصميم)
          // هنا سنرسلها كـ JSON String عادي لأن التشفير يتم في MeshService أو يمكن أن تكون clear text لهذا النوع
          // ولكن MeshService.sendMeshMessage تتوقع encryptedContent. 
          // للتبسيط الآن سنرسل JSON كما هو. في الإنتاج يجب تشفيرها بالمفتاح العام للطرف الآخر (الذي حصلنا عليه للتو!)
          
          final profileJson = jsonEncode(myProfile);
          
          LogService.info('📤 جاري إرسال بياناتي للطرف الآخر (Mutual Exchange)...');
          
          // TODO: تشفير البيانات باستخدام publicKey للطرف الآخر (contactId)
          // حالياً نرسلها كما هي
          
          await meshService.sendMeshMessage(
            contactId, 
            profileJson, 
            type: MeshMessage.typeContactExchange,
          );
          
          if (mounted) {
             // Show toast/snackbar
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contact added - Sending my profile...'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        LogService.error('فشل في إرسال بياناتي (Mutual Exchange)', e);
        // لا نوقف العملية، فقط نسجل الخطأ
      }
      // ===============================================================
      
      // إنشاء محادثة جديدة
      const uuid = Uuid();
      final chatId = uuid.v4();
      await database.insertChat(
        ChatsTableCompanion.insert(
          id: chatId,
          peerId: Value(contactId),
          name: const Value.absent(),
          lastMessage: const Value.absent(),
          lastUpdated: Value(DateTime.now()),
          isGroup: const Value(false),
          memberCount: const Value.absent(),
          avatarColor: Value(_generateAvatarColor(name ?? 'Unknown')),
        ),
      );
      
      // الانتقال إلى شاشة المحادثة
      await _navigateToChat(contactId, database);
      
    } catch (e) {
      LogService.error('خطأ في معالجة QR Code', e);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError('${l10n.errorProcessingQrCode}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// توليد لون للصورة الشخصية
  int _generateAvatarColor(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return (0xFF000000 | (hash & 0x00FFFFFF)).abs();
  }

  /// الانتقال إلى شاشة المحادثة
  Future<void> _navigateToChat(String contactId, AppDatabase database) async {
    // الحصول على المحادثة
    final chat = await database.getChatByPeerId(contactId);
    if (chat == null) {
      LogService.error('المحادثة غير موجودة: $contactId');
      return;
    }
    
    // الحصول على جهة الاتصال
    final contact = await database.getContactById(contactId);
    if (contact == null) {
      LogService.error('جهة الاتصال غير موجودة: $contactId');
      return;
    }
    
    // إنشاء ChatModel
    final chatModel = ChatModel(
      id: chat.id,
      name: contact.name,
      time: chat.lastUpdated,
      avatarColor: chat.avatarColor,
      publicKey: contact.publicKey,
      isGroup: false,
    );
    
    // الانتقال إلى شاشة المحادثة
    if (mounted) {
      context.go('${AppRoutes.chat}/${chat.id}', extra: chatModel);
    }
  }

  /// إظهار رسالة خطأ
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.scanQrCode),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64.sp,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.cameraPermissionRequired,
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.cameraPermissionDenied,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  _requestCameraPermission();
                },
                child: Text(l10n.grantPermission),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQrCode(barcode.rawValue);
                  break; // معالجة أول QR Code فقط
                }
              }
            },
          ),
          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 100.h),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: Container()),
                      // Scanning Area
                      Container(
                        width: 250.w,
                        height: 250.w,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
                SizedBox(height: 100.h),
              ],
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100.h,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  if (_isProcessing)
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            l10n.processing,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        l10n.placeQrInFrame,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


