import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutUs),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 40.h),
            
            // Logo & Version
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    // Placeholder for logo if image asset fails
                    child: Icon(
                      Icons.hub, 
                      size: 60.sp, 
                      color: theme.colorScheme.primary
                    ), 
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  
                  SizedBox(height: 24.h),
                  
                  Text(
                    l10n.appName,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                  
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      return Text(
                        '${l10n.version} ${snapshot.data?.version ?? '1.0.0'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
            
            SizedBox(height: 48.h),
            
            // How it Works Timeline
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.howItWorks,
                    style: theme.textTheme.headlineSmall,
                  ).animate().fadeIn(delay: 400.ms),
                  
                  SizedBox(height: 24.h),
                  
                  _buildTimelineItem(
                    context,
                    index: 1,
                    title: l10n.scanQrCode,
                    description: l10n.scanQrDescription,
                    icon: Icons.qr_code_scanner,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    context,
                    index: 2,
                    title: l10n.autoConnect,
                    description: l10n.autoConnectDescription,
                    icon: Icons.wifi_tethering,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    context,
                    index: 3,
                    title: l10n.secureChat,
                    description: l10n.secureChatDescription,
                    icon: Icons.chat_bubble_outline,
                    isLast: true,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 48.h),
            
            // Credits
            Text(
              l10n.designedForResilience,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white30,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line
          Column(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Icon(icon, size: 20.sp, color: theme.colorScheme.primary),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (400 + (index * 100)).ms).slideX(begin: 0.1);
  }
}
