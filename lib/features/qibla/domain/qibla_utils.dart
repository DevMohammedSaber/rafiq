import 'dart:math' as math;

/// Qibla utility functions for calculating bearing and distance to Kaaba
/// Uses great-circle initial bearing formula and haversine formula
class QiblaUtils {
  // Kaaba coordinates in Mecca, Saudi Arabia
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  // Earth radius in kilometers
  static const double earthRadiusKm = 6371.0;

  /// Private constructor to prevent instantiation
  QiblaUtils._();

  /// Converts degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Converts radians to degrees
  static double _toDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }

  /// Normalizes degrees to range [0, 360)
  static double normalizeDegrees(double degrees) {
    double result = degrees % 360.0;
    if (result < 0) {
      result += 360.0;
    }
    return result;
  }

  /// Calculates the great-circle initial bearing from user location to Kaaba
  /// Returns bearing in degrees [0..360) where 0 is North, 90 is East, etc.
  ///
  /// Uses the formula:
  /// bearing = atan2(sin(dLon) * cos(lat2),
  ///                 cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon))
  static double bearingToQibla(double userLat, double userLng) {
    final double lat1 = _toRadians(userLat);
    final double lat2 = _toRadians(kaabaLatitude);
    final double dLon = _toRadians(kaabaLongitude - userLng);

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double bearingRad = math.atan2(y, x);
    final double bearingDeg = _toDegrees(bearingRad);

    return normalizeDegrees(bearingDeg);
  }

  /// Calculates the distance from user location to Kaaba using haversine formula
  /// Returns distance in kilometers
  ///
  /// Uses the formula:
  /// a = sin^2(dLat/2) + cos(lat1) * cos(lat2) * sin^2(dLon/2)
  /// c = 2 * atan2(sqrt(a), sqrt(1-a))
  /// d = R * c
  static double distanceToKaabaKm(double userLat, double userLng) {
    final double lat1 = _toRadians(userLat);
    final double lat2 = _toRadians(kaabaLatitude);
    final double dLat = _toRadians(kaabaLatitude - userLat);
    final double dLon = _toRadians(kaabaLongitude - userLng);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Formats distance appropriately (km or m)
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Default Cairo coordinates (Egypt) as fallback
  static const double cairoLatitude = 30.0444;
  static const double cairoLongitude = 31.2357;
}
