import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Check if location services are enabled and request permissions
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get current location as address
  Future<String?> getCurrentLocationAddress() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  /// Get city name from coordinates
  Future<String?> getCityFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
      }
      return null;
    } catch (e) {
      print('Error getting city: $e');
      return null;
    }
  }

  /// Get address from coordinates
  Future<Map<String, String>?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return {
          'street': place.street ?? '',
          'locality': place.locality ?? '',
          'subAdministrativeArea': place.subAdministrativeArea ?? '',
          'administrativeArea': place.administrativeArea ?? '',
          'country': place.country ?? '',
          'postalCode': place.postalCode ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  /// Get coordinates from address
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert to km
  }

  /// Get distance text from current location
  Future<String?> getDistanceFromCurrentLocation(double lat, double lng) async {
    try {
      final currentPosition = await getCurrentPosition();
      if (currentPosition == null) return null;

      final distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lng,
      );

      if (distance < 1) {
        return '${(distance * 1000).round()} m away';
      } else if (distance < 10) {
        return '${distance.toStringAsFixed(1)} km away';
      } else {
        return '${distance.round()} km away';
      }
    } catch (e) {
      return null;
    }
  }

  /// Watch position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    );
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permissions)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
