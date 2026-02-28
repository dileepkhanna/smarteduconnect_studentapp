import 'package:flutter/material.dart';

/// Reusable logout confirmation dialog used across Parent app.
Future<bool> showLogoutConfirmDialog(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final readable = isDark ? Colors.white : const Color(0xFF111827);

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        title: Text(
          'Logout',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: readable,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: scheme.error,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Log out of your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: readable,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      );
    },
  );

  return result == true;
}
