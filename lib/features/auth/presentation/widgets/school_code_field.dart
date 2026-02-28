import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';

class SchoolCodeField extends StatelessWidget {
  const SchoolCodeField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'School Code',
      hint: 'Enter your school code',
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      prefixIcon: Icons.school_outlined, // ✅ IconData (not Icon widget)
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        _UpperCaseTextFormatter(),
      ],
      validator: Validators.schoolCode,
      onSubmitted: onSubmitted,
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
