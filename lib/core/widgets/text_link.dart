import 'package:flutter/material.dart';

class TextLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;
  final Color textColor;
  final Color linkColor;

  const TextLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
    this.textColor = Colors.grey,
    this.linkColor = const Color(0xFF4A90D9),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: TextStyle(color: textColor, fontSize: 14)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkText,
            style: TextStyle(
              color: linkColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
