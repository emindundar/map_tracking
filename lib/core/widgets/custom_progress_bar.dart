import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CustomProgressBar extends StatelessWidget {
  final double size;
  final Color? color;

  const CustomProgressBar({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SpinKitWanderingCubes(
      color: color ?? Theme.of(context).colorScheme.primary,
      size: size,
    );
  }
}
