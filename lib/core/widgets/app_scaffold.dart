// lib/core/widgets/app_scaffold.dart
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_appbar.dart';

/// Common scaffold wrapper for consistent padding, safe area,
/// background color, and optional pull-to-refresh.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.onRefresh,
    this.extendBodyBehindAppBar = false,
    this.leading,
    this.drawer,
    this.bottomNavigationBar,
    this.showBack = true,
    this.onBack,
    this.backgroundColor,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;
  final bool extendBodyBehindAppBar;
  final Widget? leading;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool showBack;
  final VoidCallback? onBack;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ?? theme.scaffoldBackgroundColor;

    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? <Color>[
              bg,
              scheme.primary.withValues(alpha: 0.18),
              scheme.surfaceContainerLowest.withValues(alpha: 0.78),
            ]
          : <Color>[
              scheme.primary.withValues(alpha: 0.16),
              scheme.secondary.withValues(alpha: 0.10),
              bg,
            ],
    );

    final paddedBody = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.screenV,
      ),
      child: body,
    );

    final content = onRefresh == null
        ? paddedBody
        : RefreshIndicator(
            onRefresh: onRefresh!,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [paddedBody],
            ),
          );

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawer: drawer,
      appBar: AppAppBar(
        title: title,
        leading: leading,
        showBack: showBack,
        hasDrawer: drawer != null,
        actions: actions,
        onBack: onBack,
        backgroundColor: backgroundColor,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: !extendBodyBehindAppBar,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: bodyGradient),
          child: content,
        ),
      ),
    );
  }
}
