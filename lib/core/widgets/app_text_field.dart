import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable TextField with clean UI + supports `initialValue` (fixes your error).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue, // ✅ used by profile screens
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.enableObscureToggle = true,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.autofillHints,
  });

  final String label;
  final String? hint;

  /// Provide controller OR initialValue. If controller is null, internal controller is used.
  final TextEditingController? controller;

  /// ✅ Fix: screens use `initialValue:`; old widget didn’t support it.
  final String? initialValue;

  final bool enabled;
  final bool readOnly;

  final bool obscureText;
  final bool enableObscureToggle;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  final IconData? prefixIcon;

  /// Can be IconButton or any widget (e.g. show/hide password)
  final Widget? suffixIcon;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final FormFieldValidator<String>? validator;

  final List<TextInputFormatter>? inputFormatters;

  final int maxLines;
  final int? minLines;

  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _internalController;
  TextEditingController get _controller => widget.controller ?? _internalController;

  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController(text: widget.initialValue ?? '');
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If using internal controller & initialValue changed, update the text
    if (widget.controller == null && oldWidget.initialValue != widget.initialValue) {
      _internalController.text = widget.initialValue ?? '';
    }

    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1),
      );

  @override
  Widget build(BuildContext context) {
    final baseFill = AppColors.surface;
    final disabledFill = AppColors.surfaceSoft;

    final suffix = widget.suffixIcon ??
        (widget.obscureText && widget.enableObscureToggle
            ? IconButton(
                tooltip: _obscure ? 'Show' : 'Hide',
                onPressed: widget.enabled
                    ? () => setState(() => _obscure = !_obscure)
                    : null,
                icon: Icon(
                  _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              )
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.obscureText ? 1 : widget.minLines,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: widget.enabled ? baseFill : disabledFill,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 20, color: AppColors.textSecondary),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: _border(AppColors.border),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.brandPrimary),
            disabledBorder: _border(AppColors.borderSoft),
            errorBorder: _border(AppColors.danger),
            focusedErrorBorder: _border(AppColors.danger),
          ),
        ),
      ],
    );
  }
}
