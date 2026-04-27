import 'package:flutter/material.dart';

/// Scaffold متجاوب يستخدم ScreenUtil
/// يوفر واجهة موحدة لجميع الشاشات
class ResponsiveScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final bool showAppBar;

  const ResponsiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: body,
      ),
    );
  }
}

