import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/qibla_utils.dart';
import '../../../profile/domain/models/user_settings.dart';
import 'qibla_state.dart';

/// Qibla Cubit for managing Qibla direction and compass heading
class QiblaCubit extends Cubit<QiblaState> {
  /// Compass event stream subscription
  StreamSubscription<CompassEvent>? _compassSubscription;

  /// Current user location from settings
  final UserLocation? _userLocation;

  /// EMA smoothing factor for compass heading (0-1, lower = smoother)
  static const double _smoothingFactor = 0.15;

  /// Accuracy threshold for calibration warning (in degrees)
  static const double _accuracyThreshold = 15.0;

  /// Previous smoothed heading for EMA calculation
  double? _smoothedHeading;

  QiblaCubit({UserLocation? userLocation})
    : _userLocation = userLocation,
      super(const QiblaInitial());

  /// Initialize Qibla feature - load location and start compass
  Future<void> init() async {
    emit(const QiblaLoading());

    try {
      // Step 1: Get user location
      final locationResult = await _getLocation();
      if (locationResult == null) {
        return; // State already emitted in _getLocation
      }

      final double userLat = locationResult.lat;
      final double userLng = locationResult.lng;
      final LocationSource source = locationResult.source;

      // Step 2: Calculate Qibla bearing and distance
      final double qiblaBearing = QiblaUtils.bearingToQibla(userLat, userLng);
      final double distanceKm = QiblaUtils.distanceToKaabaKm(userLat, userLng);

      // Step 3: Check compass availability and start listening
      final bool compassAvailable = await _isCompassAvailable();

      if (!compassAvailable) {
        emit(
          QiblaSensorUnavailable(
            qiblaBearing: qiblaBearing,
            distanceKm: distanceKm,
            userLat: userLat,
            userLng: userLng,
            locationSource: source,
          ),
        );
        return;
      }

      // Emit initial loaded state without heading
      emit(
        QiblaLoaded(
          userLat: userLat,
          userLng: userLng,
          qiblaBearing: qiblaBearing,
          distanceKm: distanceKm,
          heading: null,
          accuracy: null,
          needsCalibration: true,
          locationSource: source,
        ),
      );

      // Start compass stream
      _startCompassStream();
    } catch (e) {
      emit(QiblaError(e.toString()));
    }
  }

  /// Get location from settings, GPS, or fallback
  Future<_LocationResult?> _getLocation() async {
    // Check if we have location from settings
    if (_userLocation != null &&
        _userLocation.lat != null &&
        _userLocation.lng != null) {
      return _LocationResult(
        lat: _userLocation.lat!,
        lng: _userLocation.lng!,
        source: LocationSource.settings,
      );
    }

    // Check if auto location is enabled in settings
    if (_userLocation?.useAutoLocation == true) {
      // Request location permission
      final permissionStatus = await Permission.location.request();

      if (!permissionStatus.isGranted) {
        emit(const QiblaPermissionDenied(permissionType: 'location'));
        return null;
      }

      // Try to get GPS location
      try {
        final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Fall back to Cairo
          return _LocationResult(
            lat: QiblaUtils.cairoLatitude,
            lng: QiblaUtils.cairoLongitude,
            source: LocationSource.fallback,
          );
        }

        final position =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Location timeout'),
            );

        return _LocationResult(
          lat: position.latitude,
          lng: position.longitude,
          source: LocationSource.gps,
        );
      } catch (e) {
        // Fall back to Cairo on error
        return _LocationResult(
          lat: QiblaUtils.cairoLatitude,
          lng: QiblaUtils.cairoLongitude,
          source: LocationSource.fallback,
        );
      }
    }

    // Fallback to Cairo coordinates
    return _LocationResult(
      lat: QiblaUtils.cairoLatitude,
      lng: QiblaUtils.cairoLongitude,
      source: LocationSource.fallback,
    );
  }

  /// Check if compass sensor is available
  Future<bool> _isCompassAvailable() async {
    try {
      // Try to get a single event to check availability
      final events = FlutterCompass.events;
      if (events == null) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start listening to compass events
  void _startCompassStream() {
    _compassSubscription?.cancel();

    final events = FlutterCompass.events;
    if (events == null) {
      // Sensor became unavailable
      _handleSensorUnavailable();
      return;
    }

    _compassSubscription = events.listen(
      (CompassEvent event) {
        _onCompassEvent(event);
      },
      onError: (error) {
        _handleSensorUnavailable();
      },
    );
  }

  /// Handle compass event with EMA smoothing
  void _onCompassEvent(CompassEvent event) {
    final currentState = state;
    if (currentState is! QiblaLoaded) return;

    final double? rawHeading = event.heading;
    if (rawHeading == null) {
      // Emit with null heading but keep other data
      emit(currentState.copyWith(heading: null, needsCalibration: true));
      return;
    }

    // Apply EMA smoothing to reduce jitter
    final double smoothedHeading = _applySmoothing(rawHeading);

    // Check accuracy for calibration warning
    final double? accuracy = event.accuracy;
    final bool needsCalibration =
        accuracy == null || accuracy < 0 || accuracy > _accuracyThreshold;

    emit(
      QiblaLoaded(
        userLat: currentState.userLat,
        userLng: currentState.userLng,
        qiblaBearing: currentState.qiblaBearing,
        distanceKm: currentState.distanceKm,
        heading: smoothedHeading,
        accuracy: accuracy,
        needsCalibration: needsCalibration,
        locationSource: currentState.locationSource,
      ),
    );
  }

  /// Apply Exponential Moving Average smoothing to heading
  double _applySmoothing(double rawHeading) {
    if (_smoothedHeading == null) {
      _smoothedHeading = rawHeading;
      return rawHeading;
    }

    // Handle wrap-around at 0/360 degrees
    double diff = rawHeading - _smoothedHeading!;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    _smoothedHeading = QiblaUtils.normalizeDegrees(
      _smoothedHeading! + _smoothingFactor * diff,
    );

    return _smoothedHeading!;
  }

  /// Handle sensor becoming unavailable
  void _handleSensorUnavailable() {
    final currentState = state;
    if (currentState is QiblaLoaded) {
      emit(
        QiblaSensorUnavailable(
          qiblaBearing: currentState.qiblaBearing,
          distanceKm: currentState.distanceKm,
          userLat: currentState.userLat,
          userLng: currentState.userLng,
          locationSource: currentState.locationSource,
        ),
      );
    }
  }

  /// Stop compass stream and clean up
  void stop() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _smoothedHeading = null;
  }

  /// Open app settings for permission
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Retry loading after permission denied
  Future<void> retry() async {
    await init();
  }

  @override
  Future<void> close() {
    stop();
    return super.close();
  }
}

/// Internal class for location result
class _LocationResult {
  final double lat;
  final double lng;
  final LocationSource source;

  const _LocationResult({
    required this.lat,
    required this.lng,
    required this.source,
  });
}
