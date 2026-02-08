import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/app_logo.dart';

/// شاشة التسجيل
/// تسمح للمستخدم بإنشاء هوية محلية مرتبطة بالجهاز
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = ref.read(authServiceProvider.notifier);
    final success = await authService.register(_nameController.text.trim());

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // الانتقال إلى Home
      context.go(AppRoutes.home);
    } else {
      // عرض رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.registrationFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 48.h),
                // Logo
                Hero(
                  tag: 'app_logo',
                  child: AppLogo(
                    width: 100.w,
                    height: 100.h,
                  ),
                ),
                SizedBox(height: 32.h),
                // Title
                Text(
                  l10n.createIdentity,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                // Info Text
                Text(
                  l10n.identityInfo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),
                // Nickname Input
                TextFormField(
                  key: const Key('register_name_field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.nickname,
                    hintText: l10n.nicknameHint,
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 30,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.nicknameRequired;
                    }
                    if (value.trim().length < 2) {
                      return l10n.nicknameTooShort;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32.h),
                // Register Button
                SizedBox(
                  height: 56.h,
                  child: ElevatedButton(
                    key: const Key('register_button'),
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            l10n.enterSada,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24.h),
                // Security Note
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 20.sp,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          l10n.securityNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

