import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maptracking/permission/permission_service.dart';
import 'package:maptracking/util/constants.dart';

// Permission Status Provider
final permissionStatusProvider = FutureProvider<LocationPermission>((
  ref,
) async {
  final permissionService = ref.read(permissionServiceProvider);
  return await permissionService.requestLocationPermission();
});

// Current Position Provider
final currentPositionProvider = FutureProvider<Position>((ref) async {
  final permissionService = ref.read(permissionServiceProvider);
  return await permissionService.getUserCurrentPosition();
});

// PermissionState
class PermissionState {
  final bool hasPermission;
  final bool isChecking;
  final LocationPermission? permissionStatus;
  final String permissionMessage;
  final Position? currentPosition;

  const PermissionState({
    this.hasPermission = false,
    this.isChecking = true,
    this.permissionStatus,
    this.permissionMessage = AppStrings.checkingPermission,
    this.currentPosition,
  });

  PermissionState copyWith({
    bool? hasPermission,
    bool? isChecking,
    LocationPermission? permissionStatus,
    String? permissionMessage,
    Position? currentPosition,
  }) {
    return PermissionState(
      hasPermission: hasPermission ?? this.hasPermission,
      isChecking: isChecking ?? this.isChecking,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      permissionMessage: permissionMessage ?? this.permissionMessage,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}

// PermissionViewModel
class PermissionViewModel extends StateNotifier<PermissionState> {
  final PermissionService _permissionService;

  PermissionViewModel(this._permissionService)
    : super(const PermissionState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await checkPermission();
  }

  Future<void> checkPermission() async {
    state = state.copyWith(
      isChecking: true,
      permissionMessage: AppStrings.checkingPermission,
    );

    final status = await _permissionService.requestLocationPermission();

    final checkHasPermission =
        status == LocationPermission.whileInUse ||
        status == LocationPermission.always;

    if (checkHasPermission) {
      await getCurrentPosition();
      state = state.copyWith(permissionMessage: AppStrings.permissionGranted);
    }

    state = state.copyWith(
      hasPermission: checkHasPermission,
      isChecking: false,
      permissionStatus: status,
    );
  }

  Future<void> requestPermission() async {
    await checkPermission();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
    await checkPermission();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
    await checkPermission();
  }

  Future<void> getCurrentPosition() async {
    final position = await _permissionService.getUserCurrentPosition();
    state = state.copyWith(currentPosition: position);
  }

  void onPermissionGranted() {
    getCurrentPosition();
    state = state.copyWith(hasPermission: true, isChecking: false);
  }
}

// PermissionViewModel Provider
final permissionViewModelProvider =
    StateNotifierProvider<PermissionViewModel, PermissionState>((ref) {
      final permissionService = ref.read(permissionServiceProvider);
      return PermissionViewModel(permissionService);
    });
