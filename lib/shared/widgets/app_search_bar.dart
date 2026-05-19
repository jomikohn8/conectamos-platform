import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hint = 'Buscar...',
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _ctrl;
  late final bool _ownsController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ctrl = widget.controller ?? TextEditingController();
    _hasText = _ctrl.text.isNotEmpty;
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _ctrl.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clear() {
    _ctrl.clear();
    widget.onChanged('');
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.ctText3),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 17,
          color: AppColors.ctText3,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: AppColors.ctText3,
                ),
                onPressed: _clear,
                padding: EdgeInsets.zero,
              )
            : null,
        filled: true,
        fillColor: AppColors.ctSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: _border(AppColors.ctBorder2),
        enabledBorder: _border(AppColors.ctBorder2),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ctTeal, width: 1.5),
        ),
      ),
    );
  }
}
