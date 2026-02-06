import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../l10n/app_localizations.dart';

/// شاشة سياسة الخصوصية
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyPolicy,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.lastUpdated,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 32.h),
            _buildSection(
              context,
              title: l10n.noDataCollection,
              content: l10n.noDataCollectionDescription,
            ),
            SizedBox(height: 24.h),
            _buildSection(
              context,
              title: l10n.localStorage,
              content: l10n.localStorageDescription,
            ),
            SizedBox(height: 24.h),
            _buildSection(
              context,
              title: l10n.encryption,
              content: l10n.encryptionDescription,
            ),
            SizedBox(height: 24.h),
            _buildSection(
              context,
              title: l10n.meshNetworking,
              content: l10n.meshNetworkingDescription,
            ),
            SizedBox(height: 24.h),
            _buildSection(
              context,
              title: l10n.openSource,
              content: l10n.openSourceDescription,
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15.sp,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

