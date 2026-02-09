import 'package:flutter/material.dart';
import 'package:maptracking/core/widgets/widgets.dart';
import 'package:maptracking/map/location_result_model.dart';
import 'package:maptracking/map/map_view_model.dart';
import 'package:maptracking/util/constants.dart';

class MapSearchSheet extends StatelessWidget {
  final MapState mapState;
  final ValueChanged<LocationResult> onStartResultSelected;
  final ValueChanged<LocationResult> onDestinationResultSelected;
  final double maxHeightFactor;

  const MapSearchSheet({
    super.key,
    required this.mapState,
    required this.onStartResultSelected,
    required this.onDestinationResultSelected,
    this.maxHeightFactor = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * maxHeightFactor;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Material(
                color: Colors.white,
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            AppStrings.searchResultsTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (mapState.isSearching)
                            const CustomProgressBar(size: 18),
                        ],
                      ),
                    ),
                    Flexible(
                      child: _buildContent(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (mapState.isSearching && mapState.searchResults.isEmpty) {
      return Center(
        child: Text(
          AppStrings.searching,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    if (mapState.searchResults.isEmpty && mapState.hasSearched) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              AppStrings.noResultsFound,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: ListView.builder(
        itemCount: mapState.searchResults.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final result = mapState.searchResults[index];
          final isStart = mapState.activeSearchField == SearchField.start;
          return ListTile(
            leading: Icon(
              isStart ? Icons.trip_origin : Icons.location_on,
              color: isStart ? Colors.green : Colors.red,
            ),
            title: Text(
              result.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {
              if (isStart) {
                onStartResultSelected(result);
              } else {
                onDestinationResultSelected(result);
              }
            },
          );
        },
      ),
    );
  }
}
