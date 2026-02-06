import 'package:flutter/material.dart';
import 'package:maptracking/map/location_result_model.dart';
import 'package:maptracking/map/map_view_model.dart';
import 'package:maptracking/util/constants.dart';

class MapSearchWidgets extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController destinationController;
  final MapState mapState;
  final ValueChanged<String> onStartSearchChanged;
  final ValueChanged<String> onDestinationSearchChanged;
  final ValueChanged<LocationResult> onStartResultSelected;
  final ValueChanged<LocationResult> onDestinationResultSelected;
  final VoidCallback onUseCurrentLocationAsStart;
  final VoidCallback onClearDestination;

  const MapSearchWidgets({
    super.key,
    required this.startController,
    required this.destinationController,
    required this.mapState,
    required this.onStartSearchChanged,
    required this.onDestinationSearchChanged,
    required this.onStartResultSelected,
    required this.onDestinationResultSelected,
    required this.onUseCurrentLocationAsStart,
    required this.onClearDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(blurRadius: 10, color: Colors.black12),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trip_origin,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: startController,
                          textInputAction: TextInputAction.search,
                          onChanged: onStartSearchChanged,
                          onTap: () {
                            if (startController.text ==
                                AppStrings.currentLocation) {
                              startController.clear();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: AppStrings.startPointHint,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (startController.text.isNotEmpty &&
                                    startController.text !=
                                        AppStrings.currentLocation)
                                  IconButton(
                                    icon: Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      startController.clear();
                                      onUseCurrentLocationAsStart();
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(
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
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: destinationController,
                          textInputAction: TextInputAction.search,
                          onChanged: onDestinationSearchChanged,
                          decoration: InputDecoration(
                            hintText: AppStrings.destinationHint,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            suffixIcon: destinationController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      destinationController.clear();
                                      onClearDestination();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (mapState.searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(blurRadius: 10, color: Colors.black12),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: mapState.searchResults.length,
                itemBuilder: (context, index) {
                  final result = mapState.searchResults[index];
                  return ListTile(
                    leading: Icon(
                      mapState.activeSearchField == SearchField.start
                          ? Icons.trip_origin
                          : Icons.location_on,
                      color: mapState.activeSearchField == SearchField.start
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(
                      result.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      if (mapState.activeSearchField == SearchField.start) {
                        onStartResultSelected(result);
                      } else {
                        onDestinationResultSelected(result);
                      }
                    },
                  );
                },
              ),
            )
          else if (mapState.hasSearched &&
              mapState.searchResults.isEmpty &&
              !mapState.isSearching)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(blurRadius: 10, color: Colors.black12),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_off, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    AppStrings.noResultsFound,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
