import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? country;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.country,
  });

  @override
  String toString() => address;

  String get shortAddress {
    if (city != null) {
      return '$city${country != null ? ', $country' : ''}';
    }
    return address;
  }
}

class LocationService {
  static const Duration _locationTimeout = Duration(seconds: 15);

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    final permission = await Permission.location.status;
    return permission == PermissionStatus.granted;
  }

  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission == PermissionStatus.granted;
  }

  /// Check if location services are enabled on device
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location with timeout and error handling
  static Future<LocationData?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        throw LocationServiceException('Location services are disabled');
      }

      // Check permissions
      if (!await hasLocationPermission()) {
        final hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          throw LocationServiceException('Location permission denied');
        }
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(_locationTimeout);

      // Convert coordinates to address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        throw LocationServiceException('Could not determine address');
      }

      final placemark = placemarks.first;
      final address = _formatAddress(placemark);

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: placemark.locality,
        country: placemark.country,
      );
    } on TimeoutException {
      throw LocationServiceException('Location request timed out');
    } on PermissionDeniedException {
      throw LocationServiceException('Location permission denied');
    } on LocationServiceDisabledException {
      throw LocationServiceException('Location services disabled');
    } catch (e) {
      if (e is LocationServiceException) rethrow;
      throw LocationServiceException('Failed to get location: $e');
    }
  }

  /// Search for locations based on query
  static Future<List<LocationData>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final locations = await locationFromAddress(query);
      final List<LocationData> results = [];

      for (final location in locations.take(5)) {
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            final address = _formatAddress(placemark);

            results.add(LocationData(
              latitude: location.latitude,
              longitude: location.longitude,
              address: address,
              city: placemark.locality,
              country: placemark.country,
            ));
          }
        } catch (e) {
          // Skip locations that can't be reverse geocoded
          continue;
        }
      }

      return results;
    } catch (e) {
      throw LocationServiceException('Failed to search locations: $e');
    }
  }

  /// Format address from placemark
  static String _formatAddress(Placemark placemark) {
    final components = <String>[];

    // Add street number and name
    if (placemark.street?.isNotEmpty == true) {
      components.add(placemark.street!);
    }

    // Add locality (city/town)
    if (placemark.locality?.isNotEmpty == true) {
      components.add(placemark.locality!);
    }

    // Add administrative area (state/province)
    if (placemark.administrativeArea?.isNotEmpty == true) {
      components.add(placemark.administrativeArea!);
    }

    // Add country
    if (placemark.country?.isNotEmpty == true) {
      components.add(placemark.country!);
    }

    // If no components, try name or formatted address
    if (components.isEmpty) {
      if (placemark.name?.isNotEmpty == true) {
        return placemark.name!;
      }
      return 'Unknown Location';
    }

    return components.join(', ');
  }

  /// Get distance between two locations in kilometers
  static double getDistance(LocationData from, LocationData to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert meters to kilometers
  }
}

class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);
  @override
  String toString() => 'LocationServiceException: $message';
}
