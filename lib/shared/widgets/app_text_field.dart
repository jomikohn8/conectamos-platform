import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.helperText,
    this.errorText,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final String? helperText;
  final String? errorText;
  final Widget? suffix;
  final Widget? prefix;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  bool get _hasError => errorText != null;

  OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.formLabel),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          maxLines: obscureText ? 1 : maxLines,
          minLines: (obscureText || maxLines <= 1) ? null : maxLines,
          style: AppTextStyles.body.copyWith(
            color: enabled ? AppColors.ctText : AppColors.ctText3,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.ctText3),
            filled: true,
            fillColor: enabled ? AppColors.ctSurface : AppColors.ctSurface2,
            suffixIcon: suffix,
            prefixIcon: prefix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: _border(
              _hasError ? AppColors.ctDanger : AppColors.ctBorder2,
            ),
            focusedBorder: _border(
              _hasError ? AppColors.ctDanger : AppColors.ctTeal,
              width: 1.5,
            ),
            disabledBorder: _border(AppColors.ctBorder),
            errorBorder: _border(AppColors.ctDanger, width: 1.5),
            focusedErrorBorder: _border(AppColors.ctDanger, width: 1.5),
            border: _border(AppColors.ctBorder2),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 3),
          Text(
            errorText!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.ctDanger),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 3),
          Text(
            helperText!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.ctText3),
          ),
        ],
      ],
    );
  }
}
