import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/enums.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant? variant;
  final Color? color;
  final double? width;
  final double height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant,
    this.color,
    this.width,
    this.height = 50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final String buttonText = text.isNotEmpty ? text : (label ?? '');
    final effectiveVariant = variant ?? ButtonVariant.filled;
    final buttonHeight = height < 46 ? 46.0 : height;
    return SizedBox(
      width: width ?? double.infinity,
      height: buttonHeight,
      child: switch (effectiveVariant) {
        ButtonVariant.filled => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(0, buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _buildChild(buttonText),
        ),
        ButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? AppColors.primary,
            minimumSize: Size(0, buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            side: BorderSide(color: color ?? AppColors.primary, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildChild(buttonText),
        ),
        ButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color ?? AppColors.primary,
            minimumSize: Size(0, buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: _buildChild(buttonText),
        ),
      },
    );
  }

  Widget _buildChild(String buttonText) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    final label = Text(
      buttonText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
    if (icon == null) return label;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    );
  }
}
