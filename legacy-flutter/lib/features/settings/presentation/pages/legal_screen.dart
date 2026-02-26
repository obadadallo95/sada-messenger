import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../../../core/constants/legal_content.dart';
import '../../../../core/widgets/mesh_gradient_background.dart';
import 'package:sada/l10n/generated/app_localizations.dart';

/// شاشة عرض المحتوى القانوني (Privacy Policy / Terms of Service)
class LegalScreen extends StatelessWidget {
  final String type; // 'privacy' or 'terms'

  const LegalScreen({
    super.key,
    required this.type,
  });

  String get _content {
    switch (type) {
      case 'privacy':
        return LegalContent.privacyPolicy;
      case 'terms':
        return LegalContent.termsOfService;
      default:
        return LegalContent.privacyPolicy;
    }
  }

  String _getTitle(AppLocalizations l10n) {
    switch (type) {
      case 'privacy':
        return l10n.privacyPolicy;
      case 'terms':
        return l10n.termsOfService;
      default:
        return l10n.privacyPolicy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _getTitle(l10n),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: theme.colorScheme.surface.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      body: MeshGradientBackground(
        child: SafeArea(
          child: Container(
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.w,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface.withValues(alpha: 0.3),
                  theme.colorScheme.surface.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Markdown(
                  data: _content,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    h2: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    h3: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    p: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                    strong: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    code: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: 'monospace',
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      color: theme.colorScheme.primary,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    blockquote: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    listBullet: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                    a: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  shrinkWrap: true,
                ),
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

