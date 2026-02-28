// lib/features/auth/presentation/widgets/password_strength_hint.dart
import 'package:flutter/material.dart';

class PasswordStrengthHint extends StatelessWidget {
  const PasswordStrengthHint({
    super.key,
    required this.password,
    this.minLength = 8,
  });

  final String password;
  final int minLength;

  @override
  Widget build(BuildContext context) {
    final checks = _buildChecks(password, minLength);
    final passedCount = checks.where((c) => c.passed).length;
    final progress = (passedCount / checks.length).clamp(0.0, 1.0);

    final scheme = Theme.of(context).colorScheme;
    final strengthLabel = _strengthLabel(passedCount);
    final strengthColor = _strengthColor(scheme, passedCount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, size: 18, color: strengthColor),
              const SizedBox(width: 8),
              Text(
                'Password strength: $strengthLabel',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _withAlpha(strengthColor, 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            ),
          ),
          const SizedBox(height: 12),
          ...checks.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    c.passed ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: c.passed ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<_Check> _buildChecks(String p, int minLength) {
    final hasLower = RegExp(r'[a-z]').hasMatch(p);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(p);
    final hasDigit = RegExp(r'\d').hasMatch(p);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
    final hasLen = p.length >= minLength;

    return <_Check>[
      _Check('At least $minLength characters', hasLen),
      _Check('Contains an uppercase letter (A–Z)', hasUpper),
      _Check('Contains a lowercase letter (a–z)', hasLower),
      _Check('Contains a number (0–9)', hasDigit),
      _Check('Contains a special character (!@#\$…)', hasSpecial),
    ];
  }

  static String _strengthLabel(int score) {
    if (score <= 1) return 'Weak';
    if (score == 2) return 'Fair';
    if (score == 3) return 'Good';
    return 'Strong';
  }

  static Color _strengthColor(ColorScheme scheme, int score) {
    if (score <= 1) return scheme.error;
    if (score == 2) return scheme.tertiary;
    if (score == 3) return scheme.secondary;
    return scheme.primary;
  }

  static Color _withAlpha(Color c, double opacity) {
    final a = (opacity * 255).round().clamp(0, 255);
    return c.withAlpha(a);
  }
}

class _Check {
  const _Check(this.label, this.passed);

  final String label;
  final bool passed;
}
