import 'package:flutter/material.dart';
import 'package:maptracking/util/constants.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController destinationController;
  final ValueChanged<String> onStartSearchChanged;
  final ValueChanged<String> onDestinationSearchChanged;
  final VoidCallback onUseCurrentLocationAsStart;
  final VoidCallback onClearDestination;

  const MapSearchBar({
    super.key,
    required this.startController,
    required this.destinationController,
    required this.onStartSearchChanged,
    required this.onDestinationSearchChanged,
    required this.onUseCurrentLocationAsStart,
    required this.onClearDestination,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SearchRow(
                  controller: startController,
                  hintText: AppStrings.startPointHint,
                  icon: Icons.trip_origin,
                  iconColor: Colors.green,
                  onChanged: onStartSearchChanged,
                  onTap: () {
                    if (startController.text == AppStrings.currentLocation) {
                      startController.clear();
                    }
                  },
                  suffix: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (startController.text.isNotEmpty &&
                          startController.text != AppStrings.currentLocation)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            startController.clear();
                            onUseCurrentLocationAsStart();
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.my_location,
                          size: 20,
                          color: Colors.blue,
                        ),
                        onPressed: onUseCurrentLocationAsStart,
                        tooltip: AppStrings.currentLocation,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),
                _SearchRow(
                  controller: destinationController,
                  hintText: AppStrings.destinationHint,
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  onChanged: onDestinationSearchChanged,
                  suffix: destinationController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            destinationController.clear();
                            onClearDestination();
                          },
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<String> onChanged;
  final VoidCallback? onTap;
  final Widget? suffix;

  const _SearchRow({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
    this.onTap,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ),
        if (suffix != null) suffix!,
      ],
    );
  }
}
