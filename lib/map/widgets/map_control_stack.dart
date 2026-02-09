import 'package:flutter/material.dart';

class MapControlStack extends StatelessWidget {
  final bool isNavigating;
  final bool hasRoute;
  final VoidCallback onStartNavigation;
  final VoidCallback onStopNavigation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onGoToCurrentLocation;
  final bool showCurrentLocation;

  const MapControlStack({
    super.key,
    required this.isNavigating,
    required this.hasRoute,
    required this.onStartNavigation,
    required this.onStopNavigation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onGoToCurrentLocation,
    required this.showCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasRoute)
          _ControlButton(
            icon: isNavigating ? Icons.stop : Icons.navigation,
            backgroundColor: isNavigating ? Colors.red : Colors.green,
            iconColor: Colors.white,
            onPressed: isNavigating ? onStopNavigation : onStartNavigation,
          ),
        if (hasRoute) const SizedBox(height: 10),
        _ControlButton(icon: Icons.add, onPressed: onZoomIn),
        const SizedBox(height: 10),
        _ControlButton(icon: Icons.remove, onPressed: onZoomOut),
        if (showCurrentLocation) ...[
          const SizedBox(height: 10),
          _ControlButton(icon: Icons.my_location, onPressed: onGoToCurrentLocation),
        ],
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}
