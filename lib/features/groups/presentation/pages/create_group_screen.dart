import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/router/routes.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../data/groups_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// شاشة إنشاء مجموعة جديدة
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final groupsRepo = ref.read(groupsRepositoryProvider);
      final group = await groupsRepo.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        password: _isPublic ? null : _passwordController.text.trim(),
      );

      if (!mounted) return;

      // الانتقال إلى شاشة المحادثة
      context.go('${AppRoutes.chat}/${group.id}');
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إنشاء المجموعة: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createCommunity),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Illustration
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    height: 150.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.group_add,
                      size: 80.sp,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),

                // Group Name
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: TextFormField(
                    controller: _nameController,
                    style: AppTypography.bodyLarge(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.groupName,
                      hintText: l10n.groupNameHint,
                      labelStyle: AppTypography.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      hintStyle: AppTypography.bodyMedium(context).copyWith(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.group,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.groupNameRequired;
                      }
                      if (value.trim().length < 3) {
                        return l10n.groupNameTooShort;
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16.h),

                // Description
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: TextFormField(
                    controller: _descriptionController,
                    style: AppTypography.bodyLarge(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.groupDescription,
                      hintText: l10n.groupDescriptionHint,
                      labelStyle: AppTypography.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      hintStyle: AppTypography.bodyMedium(context).copyWith(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.description,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.groupDescriptionRequired;
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 24.h),

                // Privacy Switch
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        l10n.publicGroup,
                        style: AppTypography.titleMedium(context).copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        _isPublic ? l10n.publicGroupDescription : l10n.privateGroupDescription,
                        style: AppTypography.bodyMedium(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Password Field (if private)
                if (!_isPublic)
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: TextFormField(
                      controller: _passwordController,
                      style: AppTypography.bodyLarge(context).copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.groupPassword,
                        hintText: l10n.groupPasswordHint,
                        labelStyle: AppTypography.bodyMedium(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                        hintStyle: AppTypography.bodyMedium(context).copyWith(
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (!_isPublic && (value == null || value.trim().isEmpty)) {
                          return l10n.groupPasswordRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                SizedBox(height: 32.h),

                // Create Button
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: SizedBox(
                    height: 56.h,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createGroup,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(Icons.rocket_launch),
                      label: Text(
                        l10n.launchGroup,
                        style: AppTypography.buttonLarge(context).copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
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

