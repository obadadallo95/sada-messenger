import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyAndSecurity),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.security,
                  size: 48.sp,
                  color: theme.colorScheme.primary,
                ),
              ),
            ).animate().scale(duration: 500.ms),
            
            SizedBox(height: 32.h),
            
            Text(
              l10n.zeroKnowledgePromise,
              style: AppTypography.headlineSmall(context).copyWith(
                color: AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            SizedBox(height: 16.h),
            
            _buildPrivacyCard(
              context,
              icon: Icons.phonelink_erase,
              title: l10n.noPhoneNumberRequired,
              description: l10n.noPhoneNumberDescription,
              delay: 300,
            ),
            
            SizedBox(height: 16.h),
            
            _buildPrivacyCard(
              context,
              icon: Icons.lock_outline,
              title: l10n.encryption,
              description: l10n.endToEndEncryptionDescription,
              delay: 400,
            ),
            
            SizedBox(height: 16.h),
            
            _buildPrivacyCard(
              context,
              icon: Icons.storage,
              title: l10n.localDatabaseOnly,
              description: l10n.localDatabaseDescription,
              delay: 500,
            ),
            
            SizedBox(height: 32.h),
            
            Text(
              l10n.transparency,
              style: AppTypography.headlineSmall(context).copyWith(
                color: AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 600.ms),
            
            SizedBox(height: 16.h),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Text(
                      l10n.transparencyDescription,
                      style: AppTypography.bodyMedium(context).copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('https://github.com/obadadallo95/sada-messenger');
                        try {
                          // ignore: deprecated_member_use
                          await launchUrl(url);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('فشل فتح الرابط: $url'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.code),
                      label: Text(l10n.viewSourceCode),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1),

            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 28.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    style: AppTypography.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }
}
