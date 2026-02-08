import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/router/routes.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../../core/utils/log_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/security/security_providers.dart';
import '../../../../core/network/mesh_service.dart';
import '../../../chat/domain/models/chat_model.dart';

/// شاشة إضافة صديق
/// تحتوي على تبويبين: رمز QR الخاص بي ومسح رمز QR
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _flashEnabled = false;
  bool _hasPermission = false;

  // الحصول على بيانات المستخدم الحالي من AuthService
  String get _currentUserId {
    final authService = ref.read(authServiceProvider.notifier);
    return authService.currentUser?.userId ?? 'unknown';
  }

  String get _currentUserName {
    final authService = ref.read(authServiceProvider.notifier);
    return authService.currentUser?.displayName ?? 'User';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  /// التحقق من صلاحية الكاميرا
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (!_hasPermission && status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    }
  }

  /// توليد بيانات QR Code (JSON format)
  Future<String> _generateQRData() async {
    try {
      final keyManager = ref.read(keyManagerProvider);
      final publicKeyBytes = await keyManager.getPublicKey();
      final publicKeyBase64 = base64Encode(publicKeyBytes);
      
      final qrData = {
        'id': _currentUserId,
        'name': _currentUserName,
        'publicKey': publicKeyBase64,
      };
      
      return jsonEncode(qrData);
    } catch (e) {
      LogService.error('خطأ في توليد QR Code', e);
      // Fallback إلى التنسيق القديم
      return 'sada://user/$_currentUserId';
    }
  }

  /// مشاركة رمز QR
  Future<void> _shareQRCode() async {
    try {
      final qrData = await _generateQRData();
      // ignore: deprecated_member_use
      await Share.share(qrData);
    } catch (e) {
      LogService.error('خطأ في مشاركة رمز QR', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في المشاركة')),
        );
      }
    }
  }

  /// معالجة مسح رمز QR
  void _handleQRCodeDetect(String code) {
    // إيقاف الماسح مؤقتاً
    _scannerController.stop();

    // عرض BottomSheet مع تفاصيل الصديق
    _showFriendFoundSheet(code);
  }

  /// عرض BottomSheet عند العثور على صديق
  void _showFriendFoundSheet(String scannedData) {
    final l10n = AppLocalizations.of(context)!;

    // محاولة تحليل QR Code
    Map<String, dynamic>? qrData;
    String? contactId;
    String? name;
    String? publicKey;

    try {
      // محاولة تحليل JSON
      if (scannedData.startsWith('{')) {
        qrData = jsonDecode(scannedData);
        contactId = qrData?['id'] as String?;
        name = qrData?['name'] as String?;
        publicKey = qrData?['publicKey'] as String?;
      } else if (scannedData.startsWith('sada://user/')) {
        // تنسيق قديم - استخراج userId فقط
        contactId = scannedData.replaceFirst('sada://user/', '');
        name = 'Friend';
        publicKey = null; // لا يمكن الحصول على publicKey من التنسيق القديم
      } else {
        // تنسيق غير معروف
        contactId = scannedData;
        name = 'Friend';
        publicKey = null;
      }
    } catch (e) {
      LogService.error('خطأ في تحليل QR Code', e);
      contactId = scannedData;
      name = 'Friend';
      publicKey = null;
    }

    final finalContactId = contactId ?? 'unknown';
    final finalName = name ?? l10n.newFriend;
    final finalPublicKey = publicKey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            // Icon
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add,
                size: 40.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 24.h),
            // Title
            Text(
              l10n.friendFound,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16.h),
            // Friend details
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    l10n: l10n,
                    label: l10n.name,
                    value: finalName,
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    context,
                    l10n: l10n,
                    label: l10n.id,
                    value: finalContactId.length > 30
                        ? '${finalContactId.substring(0, 30)}...'
                        : finalContactId,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            // Add Friend button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _addFriendToDatabase(finalContactId, finalName, finalPublicKey);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  l10n.addFriendButton,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    ).then((_) {
      // إعادة تشغيل الماسح بعد إغلاق الـ Sheet
      _scannerController.start();
    });
  }

  /// إضافة صديق إلى قاعدة البيانات وإنشاء محادثة
  Future<void> _addFriendToDatabase(String contactId, String name, String? publicKey) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // التحقق من أن المستخدم لا يضيف نفسه
      final authService = ref.read(authServiceProvider.notifier);
      final currentUser = authService.currentUser;
      if (currentUser?.userId == contactId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.cannotAddYourself),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // الحصول على قاعدة البيانات
      final database = await ref.read(appDatabaseProvider.future);

      // التحقق من أن جهة الاتصال غير موجودة بالفعل
      final existingContact = await database.getContactById(contactId);
      
      if (existingContact != null) {
        // جهة الاتصال موجودة - الانتقال إلى المحادثة
        LogService.info('جهة الاتصال موجودة بالفعل: $contactId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.contactAlreadyExists),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
          name: name,
          publicKey: publicKey != null ? Value(publicKey) : const Value.absent(),
          avatar: const Value.absent(),
          isBlocked: const Value(false),
        ),
      );

      LogService.info('تم إضافة جهة الاتصال بنجاح: $contactId');

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
          avatarColor: Value(_generateAvatarColor(name)),
        ),
      );

      LogService.info('تم إنشاء محادثة جديدة: $chatId');

      // إرسال إشعار للصديق لإضافته في جهازه
      await _notifyFriendAdded(contactId, currentUser!);

      // عرض رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.friendAddedSuccessfully),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }

      // الانتقال إلى شاشة المحادثة
      await _navigateToChat(contactId, database);

    } catch (e) {
      LogService.error('خطأ في إضافة الصديق', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorProcessingQrCode}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// إرسال إشعار للصديق لإضافته في جهازه
  Future<void> _notifyFriendAdded(String contactId, UserData currentUser) async {
    try {
      final meshService = ref.read(meshServiceProvider);
      final encryptionService = ref.read(encryptionServiceProvider);
      final database = await ref.read(appDatabaseProvider.future);
      
      // الحصول على المفتاح العام للصديق
      final contact = await database.getContactById(contactId);
      if (contact?.publicKey == null) {
        LogService.warning('لا يوجد مفتاح عام للصديق - لن يتم إرسال الإشعار');
        return;
      }
      
      // إنشاء payload للإشعار
      final notificationData = {
        'type': 'friend_added',
        'senderId': currentUser.userId,
        'senderName': currentUser.displayName,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // تشفير الإشعار
      String encryptedNotification;
      try {
        final remotePublicKeyBytes = base64Decode(contact!.publicKey!);
        final sharedKey = await encryptionService.calculateSharedSecret(remotePublicKeyBytes);
        encryptedNotification = encryptionService.encryptMessage(
          jsonEncode(notificationData),
          sharedKey,
        );
      } catch (e) {
        LogService.error('خطأ في تشفير إشعار إضافة الصديق', e);
        return;
      }
      
      // إرسال الإشعار
      final sent = await meshService.sendMessage(contactId, encryptedNotification);
      if (sent) {
        LogService.info('تم إرسال إشعار إضافة الصديق بنجاح');
      } else {
        LogService.warning('فشل إرسال إشعار إضافة الصديق');
      }
    } catch (e) {
      LogService.error('خطأ في إرسال إشعار إضافة الصديق', e);
      // لا نرمي خطأ - هذا إشعار اختياري
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
    try {
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
    } catch (e) {
      LogService.error('خطأ في الانتقال إلى المحادثة', e);
      if (mounted) {
        context.go(AppRoutes.home);
      }
    }
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required AppLocalizations l10n,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp,
                ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addFriend),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.qr_code),
              text: l10n.myCode,
            ),
            Tab(
              icon: Icon(Icons.camera_alt),
              text: l10n.scan,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: My QR Code
          _buildMyCodeView(context, l10n, theme),
          // Tab 2: Scanner
          _buildScannerView(context, l10n, theme),
        ],
      ),
    );
  }

  /// بناء عرض رمز QR الخاص بي
  Widget _buildMyCodeView(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return FutureBuilder<String>(
      future: _generateQRData(),
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
              ],
            ),
          );
        }
        
        final qrData = snapshot.data ?? 'sada://user/$_currentUserId';

        return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            SizedBox(height: 32.h),
            // Card مع QR Code
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  children: [
                    // QR Code
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 250.w,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: theme.colorScheme.primary,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: theme.colorScheme.primary,
                      ),
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                    SizedBox(height: 24.h),
                    // اسم المستخدم
                    Text(
                      _currentUserName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // User ID
                    Text(
                      '${l10n.userId}: $_currentUserId',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32.h),
            // زر المشاركة
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _shareQRCode,
                icon: Icon(Icons.share),
                label: Text(l10n.share),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  /// بناء عرض الماسح
  Widget _buildScannerView(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 24.h),
              Text(
                l10n.cameraPermissionDenied,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.cameraPermissionRequired,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: () async {
                  await _checkCameraPermission();
                  if (_hasPermission) {
                    setState(() {});
                  }
                },
                child: Text(l10n.grantPermission),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Mobile Scanner
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final barcode = barcodes.first;
              if (barcode.rawValue != null) {
                _handleQRCodeDetect(barcode.rawValue!);
              }
            }
          },
        ),
        // Overlay مع فتحة شفافة في الوسط
        _buildScannerOverlay(context, theme),
        // زر Flashlight
        Positioned(
          top: 40.h,
          right: 16.w,
          child: FloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                _flashEnabled = !_flashEnabled;
              });
              _scannerController.toggleTorch();
            },
            backgroundColor: Colors.black54,
            child: Icon(
              _flashEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// بناء Overlay للماسح
  Widget _buildScannerOverlay(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final scanArea = 250.w;
    final top = (screenSize.height - scanArea) / 2;
    final left = (screenSize.width - scanArea) / 2;

    return Stack(
      children: [
        // طبقة سوداء شفافة تغطي الشاشة بالكامل
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        // فتحة شفافة في الوسط (Cut-out)
        Positioned(
          top: top,
          left: left,
          child: ClipRect(
            child: Container(
              width: scanArea,
              height: scanArea,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2.w,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Stack(
                children: [
                  // زوايا التوجيه
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 30.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: theme.colorScheme.primary, width: 4.w),
                          left: BorderSide(color: theme.colorScheme.primary, width: 4.w),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 30.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: theme.colorScheme.primary, width: 4.w),
                          right: BorderSide(color: theme.colorScheme.primary, width: 4.w),
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16.r),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 30.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: theme.colorScheme.primary, width: 4.w),
                          left: BorderSide(color: theme.colorScheme.primary, width: 4.w),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16.r),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: theme.colorScheme.primary, width: 4.w),
                          right: BorderSide(color: theme.colorScheme.primary, width: 4.w),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // نص التوجيه
        Positioned(
          bottom: 100.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                l10n.placeQrInFrame,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

