// lib/core/widgets/app_appbar.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = false,
    this.showBack = true,
    this.hasDrawer = false,
    this.onBack,
    this.height = kToolbarHeight,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.showDivider = true,
  });

  final String? title;
  final Widget? titleWidget;

  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  final bool centerTitle;
  final bool showBack;
  final bool hasDrawer;
  final VoidCallback? onBack;

  final double height;
  final double elevation;

  final Color? backgroundColor;
  final Color? foregroundColor;

  /// If null -> no gradient; if provided -> applied as flexibleSpace decoration.
  final Gradient? gradient;
  final bool showDivider;

  @override
  Size get preferredSize => Size.fromHeight(
        height + (bottom?.preferredSize.height ?? 0) + (showDivider ? 1 : 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();

    final bg =
        backgroundColor ?? theme.appBarTheme.backgroundColor ?? scheme.surface;
    final fg = foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        scheme.onSurface;
    final effectiveGradient =
        gradient ?? (backgroundColor == null ? AppColors.brandGradient : null);

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null && showBack && canPop) {
      resolvedLeading = IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    } else if (resolvedLeading == null && hasDrawer) {
      resolvedLeading = Builder(
        builder: (ctx) => IconButton(
          tooltip: 'Menu',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
      title: titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                )),
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
      scrolledUnderElevation: 0,
      backgroundColor: effectiveGradient == null ? bg : Colors.transparent,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      bottom: showDivider
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                (bottom?.preferredSize.height ?? 0) + 1,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bottom != null) bottom!,
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant,
                  ),
                ],
              ),
            )
          : bottom,
      flexibleSpace: effectiveGradient == null
          ? null
          : Container(
              decoration: BoxDecoration(
                gradient: effectiveGradient,
              ),
            ),
    );
  }
}
