import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maptracking/permisson/permission_service.dart';

class PermissionView extends StatefulWidget {
  const PermissionView({super.key, required this.onPermissionGranted});
  final VoidCallback onPermissionGranted;

  @override
  State<PermissionView> createState() => _PermissionViewState();
}

class _PermissionViewState extends State<PermissionView> {
  bool _isLoading = true;
  String _message = 'Konum izni kontrol ediliyor...';
  LocationPermission? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isLoading = true;
      _message = 'Konum izni kontrol ediliyor...';
    });

    final status = await PermissionService.requestLocationPermission();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _permissionStatus = status;
    });

    _handlePermissionStatus(status);
  }

  void _handlePermissionStatus(LocationPermission status) {
    switch (status) {
      case LocationPermission.denied:
        _showPermissionDialog(
          title: 'Konum İzni Gerekli',
          message: 'Uygulamanın düzgün çalışması için konum izni gereklidir.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _checkPermission();
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        );
        break;

      case LocationPermission.deniedForever:
        _showPermissionDialog(
          title: 'Konum İzni Engellendi',
          message:
              'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan izni etkinleştirin.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
                if (mounted) _checkPermission();
              },
              child: const Text('Ayarlara Git'),
            ),
          ],
        );
        break;

      case LocationPermission.whileInUse:
      case LocationPermission.always:
        setState(() {
          _message = 'Konum izni verildi!';
        });
        widget.onPermissionGranted();
        break;

      case LocationPermission.unableToDetermine:
        _showPermissionDialog(
          title: 'İzin Belirlenemedi',
          message: 'Konum izni durumu belirlenemedi. Lütfen tekrar deneyin.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _checkPermission();
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        );
        break;
    }
  }

  void _showPermissionDialog({
    required String title,
    required String message,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
              ],
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (!_isLoading &&
                  _permissionStatus != LocationPermission.always &&
                  _permissionStatus != LocationPermission.whileInUse) ...[
                ElevatedButton.icon(
                  onPressed: _checkPermission,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Kontrol Et'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Geolocator.openLocationSettings();
                    if (mounted) _checkPermission();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Konum Ayarları'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
