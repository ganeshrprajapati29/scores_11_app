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
        prefixWidget = Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(prefixIcon as IconData, size: 18, color: AppColors.primary),
          ),
        );
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          style: const TextStyle(
            fontSize: 14,
            height: 1.35,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: displayHint,
            hintMaxLines: 2,
            errorMaxLines: 3,
            isDense: false,
            hintStyle: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textHint,
            ),
            errorText: errorText,
            prefixIcon: prefixWidget,
            prefixIconConstraints: prefixWidget != null
                ? const BoxConstraints(minWidth: 54, minHeight: 50)
                : null,
            suffixIcon: suffixIcon,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            filled: true,
            fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.7),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.7),
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
