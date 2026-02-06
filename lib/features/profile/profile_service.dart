import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../core/services/auth_service.dart';
import '../../core/database/database_provider.dart';
import '../../core/utils/log_service.dart';

/// Provider لـ ProfileService
final profileServiceProvider =
    StateNotifierProvider<ProfileService, ProfileState>(
  (ref) => ProfileService(ref),
);

/// حالة الملف الشخصي
class ProfileState {
  final String? avatarBase64;
  final bool isLoading;

  ProfileState({
    this.avatarBase64,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? avatarBase64,
    bool? isLoading,
  }) {
    return ProfileState(
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// خدمة الملف الشخصي
/// تتعامل مع الصور الشخصية مع دعم Duress Mode
class ProfileService extends StateNotifier<ProfileState> {
  static const String _avatarRealKey = 'avatar_real';
  static const String _avatarDuressKey = 'avatar_duress';

  final Ref _ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final ImagePicker _imagePicker = ImagePicker();

  ProfileService(this._ref) : super(ProfileState()) {
    _loadAvatar();
  }

  /// تحميل الصورة الشخصية بناءً على AuthMode الحالي
  Future<void> _loadAvatar() async {
    try {
      final authType = _ref.read(currentAuthTypeProvider);
      final storageKey = authType == AuthType.duress
          ? _avatarDuressKey
          : _avatarRealKey;

      final avatarBase64 = await _secureStorage.read(key: storageKey);
      state = state.copyWith(avatarBase64: avatarBase64);
    } catch (e) {
      LogService.error('خطأ في تحميل الصورة الشخصية', e);
    }
  }

  /// تعيين الصورة الشخصية
  /// يختار صورة من المعرض، يضغطها، ويحفظها بناءً على AuthMode
  Future<bool> setAvatar() async {
    try {
      state = state.copyWith(isLoading: true);

      // اختيار صورة من المعرض
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // سنضغطها لاحقاً
      );

      if (pickedFile == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // ضغط الصورة
      final compressedBytes = await _compressImage(pickedFile.path);

      if (compressedBytes == null) {
        state = state.copyWith(isLoading: false);
        LogService.warning('فشل ضغط الصورة');
        return false;
      }

      // تحويل إلى Base64
      final base64String = base64Encode(compressedBytes);

      // حفظ بناءً على AuthMode
      final authType = _ref.read(currentAuthTypeProvider);
      final storageKey = authType == AuthType.duress
          ? _avatarDuressKey
          : _avatarRealKey;

      await _secureStorage.write(key: storageKey, value: base64String);

      // تحديث الحالة
      state = state.copyWith(
        avatarBase64: base64String,
        isLoading: false,
      );

      LogService.info('تم حفظ الصورة الشخصية بنجاح');
      return true;
    } catch (e) {
      LogService.error('خطأ في تعيين الصورة الشخصية', e);
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// ضغط الصورة
  /// يضغط الصورة إلى 150x150 px مع جودة 50% وتنسيق WebP
  Future<Uint8List?> _compressImage(String imagePath) async {
    try {
      // قراءة الصورة الأصلية
      final file = File(imagePath);
      final imageBytes = await file.readAsBytes();

      // ضغط الصورة
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 150,
        minWidth: 150,
        quality: 50,
        format: CompressFormat.webp,
      );

      LogService.info(
        'تم ضغط الصورة: ${imageBytes.length} -> ${compressedBytes.length} bytes',
      );

      return compressedBytes;
    } catch (e) {
      LogService.error('خطأ في ضغط الصورة', e);
      return null;
    }
  }

  /// الحصول على الصورة الشخصية الحالية
  String? getAvatar() {
    return state.avatarBase64;
  }

  /// حذف الصورة الشخصية
  Future<void> deleteAvatar() async {
    try {
      final authType = _ref.read(currentAuthTypeProvider);
      final storageKey = authType == AuthType.duress
          ? _avatarDuressKey
          : _avatarRealKey;

      await _secureStorage.delete(key: storageKey);

      state = state.copyWith(avatarBase64: null);

      LogService.info('تم حذف الصورة الشخصية');
    } catch (e) {
      LogService.error('خطأ في حذف الصورة الشخصية', e);
    }
  }

  /// تحديث الصورة عند تغيير AuthMode
  void updateAvatarForAuthMode() {
    _loadAvatar();
  }
}

