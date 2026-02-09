import 'package:flutter/material.dart';
import 'package:maptracking/util/constants.dart';

class RouteSummaryCard extends StatelessWidget {
  final double? distanceMeters;
  final double? durationSeconds;

  const RouteSummaryCard({
    super.key,
    this.distanceMeters,
    this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final distanceText = _formatDistance(distanceMeters);
    final durationText = _formatDuration(durationSeconds);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A3A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions,
                color: Color(0xFF1E2A3A),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.routeSummaryTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (distanceText != null || durationText != null)
                    const SizedBox(height: 4),
                  if (distanceText != null || durationText != null)
                    Text(
                      [distanceText, durationText]
                          .where((text) => text != null)
                          .join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatDistance(double? meters) {
    if (meters == null) return null;
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String? _formatDuration(double? seconds) {
    if (seconds == null) return null;
    final minutes = (seconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
    return '${minutes} dk';
  }
}
