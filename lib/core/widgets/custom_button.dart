import 'package:flutter/material.dart';
import 'package:maptracking/core/widgets/custom_progress_bar.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;
  final double height;
  final double borderRadius;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor = const Color(0xFF1E2A3A),
    this.foregroundColor = Colors.white,
    this.height = 56,
    this.borderRadius = 28,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, child: _buildButton(context));
  }

  Widget _buildButton(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      disabledBackgroundColor: backgroundColor.withOpacity(0.7),
    );

    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: style,
        child: CustomProgressBar(
          size: 18,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
