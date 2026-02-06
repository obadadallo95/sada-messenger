import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_logo.dart';

/// شاشة حول التطبيق
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  bool _isLoadingVersion = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _isLoadingVersion = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVersion = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutUs),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            SizedBox(height: 32.h),
            // App Logo with Hero animation
            Hero(
              tag: 'app_logo',
              child: AppLogo(
                width: 120.w,
                height: 120.h,
              ),
            ),
            SizedBox(height: 24.h),
            // App Name
            Text(
              'Sada',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            // Version
            _isLoadingVersion
                ? CircularProgressIndicator()
                : Text(
                    '${l10n.version} $_version',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
            SizedBox(height: 32.h),
            // Description
            Text(
              l10n.aboutDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16.sp,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48.h),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.code,
                  label: 'GitHub',
                  onTap: () => _launchURL('https://github.com/sada-app'),
                  color: Colors.grey[800]!,
                ),
                SizedBox(width: 16.w),
                _buildActionButton(
                  context,
                  icon: Icons.language,
                  label: l10n.website,
                  onTap: () => _launchURL('https://sada.app'),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            SizedBox(height: 48.h),
            // Developer Card
            _buildDeveloperCard(context, theme, l10n),
            SizedBox(height: 32.h),
            // Footer
            Text(
              l10n.madeWithLove,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Text(
              l10n.leadDeveloper,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 3.w,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Obada.jpg',
                  width: 100.w,
                  height: 100.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to initials if image fails
                    return Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      child: Center(
                        child: Text(
                          'OD',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Name
            Text(
              'Obada Dallo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            // Role
            Text(
              '${l10n.leadDeveloper} & ${l10n.founder}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            // Social Links Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(
                  context,
                  FontAwesomeIcons.github,
                  'https://github.com/obadadallo95',
                  theme.colorScheme.onSurface,
                ),
                SizedBox(width: 16.w),
                _buildSocialIcon(
                  context,
                  FontAwesomeIcons.linkedin,
                  'https://www.linkedin.com/in/obada-dallo-777a47a9/',
                  const Color(0xFF0077B5), // LinkedIn blue
                ),
                SizedBox(width: 16.w),
                _buildSocialIcon(
                  context,
                  FontAwesomeIcons.facebook,
                  'https://www.facebook.com/obada.dallo33',
                  const Color(0xFF1877F2), // Facebook blue
                ),
                SizedBox(width: 16.w),
                _buildSocialIcon(
                  context,
                  FontAwesomeIcons.telegram,
                  'https://t.me/obada_dallo95',
                  const Color(0xFF0088CC), // Telegram blue
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(
    BuildContext context,
    IconData icon,
    String url,
    Color color,
  ) {
    return IconButton(
      onPressed: () => _launchURL(url),
      icon: FaIcon(
        icon,
        size: 24.sp,
        color: color,
      ),
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        padding: EdgeInsets.all(12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20.sp),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 12.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}

