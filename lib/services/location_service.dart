import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  Position? currentPosition;
  bool hasPermission = false;
  bool isLoading = false;
  String? errorMessage;

  Future<void> requestLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Check if location services are enabled.
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage = 'Location services are disabled.';
        hasPermission = false;
        isLoading = false;
        notifyListeners();
        return;
      }

      // Check and request permissions.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage = 'Location permission denied.';
          hasPermission = false;
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage =
            'Location permissions are permanently denied. Please enable them in Settings.';
        hasPermission = false;
        isLoading = false;
        notifyListeners();
        return;
      }

      hasPermission = true;

      // Get current position.
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      errorMessage = 'Could not determine your location.';
      debugPrint('LocationService error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Calculates the distance in miles between the current position and given coordinates.
  /// Returns null if location is not available.
  double? distanceTo(double lat, double lng) {
    if (currentPosition == null) return null;
    final meters = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      lat,
      lng,
    );
    return meters / 1609.344; // convert to miles
  }
}
