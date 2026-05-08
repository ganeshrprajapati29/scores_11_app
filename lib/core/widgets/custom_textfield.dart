import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? labelText;
  final String? hint;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final dynamic prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool enabled;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.labelText,
    this.hint,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final String displayLabel = label ?? labelText ?? '';
    final String displayHint = hint ?? hintText ?? '';
    
    Widget? prefixWidget;
    if (prefixIcon != null) {
      if (prefixIcon is IconData) {
        prefixWidget = Icon(prefixIcon as IconData, size: 20);
      } else if (prefixIcon is Widget) {
        prefixWidget = prefixIcon;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayLabel.isNotEmpty) ...[
          Text(
            displayLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          // ✅ FIX: REMOVE THE KEY - This was causing the issue!
          // Key(displayLabel) is REMOVED
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          autofocus: autofocus,
          textInputAction: textInputAction ?? TextInputAction.next,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: displayHint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            errorText: errorText,
            prefixIcon: prefixWidget,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
          onChanged: onChanged,
          onFieldSubmitted: (_) {
            if (textInputAction == TextInputAction.next) {
              FocusScope.of(context).nextFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          validator: validator,
        ),
      ],
    );
  }
}