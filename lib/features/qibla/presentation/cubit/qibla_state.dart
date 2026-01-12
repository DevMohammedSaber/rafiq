import 'package:equatable/equatable.dart';

/// Location source types
enum LocationSource { settings, gps, fallback }

/// Qibla states for the cubit
abstract class QiblaState extends Equatable {
  const QiblaState();

  @override
  List<Object?> get props => [];
}

/// Initial state before loading
class QiblaInitial extends QiblaState {
  const QiblaInitial();
}

/// Loading state while fetching location and sensor data
class QiblaLoading extends QiblaState {
  const QiblaLoading();
}

/// Successfully loaded state with all Qibla data
class QiblaLoaded extends QiblaState {
  /// User latitude
  final double userLat;

  /// User longitude
  final double userLng;

  /// Bearing to Qibla in degrees (0-360)
  final double qiblaBearing;

  /// Distance to Kaaba in kilometers
  final double distanceKm;

  /// Current device heading in degrees (null if sensor unavailable)
  final double? heading;

  /// Compass accuracy (null if not provided by plugin)
  final double? accuracy;

  /// Whether compass needs calibration
  final bool needsCalibration;

  /// Source of location data
  final LocationSource locationSource;

  const QiblaLoaded({
    required this.userLat,
    required this.userLng,
    required this.qiblaBearing,
    required this.distanceKm,
    this.heading,
    this.accuracy,
    required this.needsCalibration,
    required this.locationSource,
  });

  @override
  List<Object?> get props => [
    userLat,
    userLng,
    qiblaBearing,
    distanceKm,
    heading,
    accuracy,
    needsCalibration,
    locationSource,
  ];

  /// Create a copy with updated heading
  QiblaLoaded copyWith({
    double? userLat,
    double? userLng,
    double? qiblaBearing,
    double? distanceKm,
    double? heading,
    double? accuracy,
    bool? needsCalibration,
    LocationSource? locationSource,
  }) {
    return QiblaLoaded(
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      qiblaBearing: qiblaBearing ?? this.qiblaBearing,
      distanceKm: distanceKm ?? this.distanceKm,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      needsCalibration: needsCalibration ?? this.needsCalibration,
      locationSource: locationSource ?? this.locationSource,
    );
  }
}

/// Permission denied state
class QiblaPermissionDenied extends QiblaState {
  /// Type of permission denied
  final String permissionType;

  const QiblaPermissionDenied({this.permissionType = 'location'});

  @override
  List<Object?> get props => [permissionType];
}

/// Sensor unavailable state - still shows bearing but no live heading
class QiblaSensorUnavailable extends QiblaState {
  /// Bearing to Qibla in degrees
  final double qiblaBearing;

  /// Distance to Kaaba in kilometers
  final double distanceKm;

  /// User latitude
  final double userLat;

  /// User longitude
  final double userLng;

  /// Source of location data
  final LocationSource locationSource;

  const QiblaSensorUnavailable({
    required this.qiblaBearing,
    required this.distanceKm,
    required this.userLat,
    required this.userLng,
    required this.locationSource,
  });

  @override
  List<Object?> get props => [
    qiblaBearing,
    distanceKm,
    userLat,
    userLng,
    locationSource,
  ];
}

/// Error state
class QiblaError extends QiblaState {
  /// Error message
  final String message;

  const QiblaError(this.message);

  @override
  List<Object?> get props => [message];
}
