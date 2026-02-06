import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maptracking/core/widgets/widgets.dart';
import 'package:maptracking/permission/permission_view_model.dart';
import 'package:maptracking/util/constants.dart';

class PermissionView extends ConsumerWidget {
  const PermissionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionViewModelProvider);
    final viewModel = ref.read(permissionViewModelProvider.notifier);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (permissionState.isChecking) ...[
                SpinKitWave(
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                permissionState.permissionMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (!permissionState.isChecking &&
                  permissionState.permissionStatus !=
                      LocationPermission.always &&
                  permissionState.permissionStatus !=
                      LocationPermission.whileInUse) ...[
                CustomButton(
                  text: AppStrings.retryButton,
                  onPressed: () => viewModel.requestPermission(),
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 12),
                if (permissionState.permissionStatus ==
                    LocationPermission.deniedForever)
                  OutlinedButton.icon(
                    onPressed: () => viewModel.openAppSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text(AppStrings.appSettingsButton),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => viewModel.openLocationSettings(),
                    icon: const Icon(Icons.location_on),
                    label: const Text(AppStrings.locationSettingsButton),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
