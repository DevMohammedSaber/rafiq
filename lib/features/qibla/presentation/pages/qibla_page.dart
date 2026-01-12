import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/qibla_utils.dart';
import '../cubit/qibla_cubit.dart';
import '../cubit/qibla_state.dart';

/// Qibla Direction Page with compass UI
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Initialize Qibla cubit
    context.read<QiblaCubit>().init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('qibla.title'.tr()), centerTitle: true),
      body: BlocBuilder<QiblaCubit, QiblaState>(
        builder: (context, state) {
          if (state is QiblaLoading || state is QiblaInitial) {
            return _buildLoadingState(context);
          }

          if (state is QiblaPermissionDenied) {
            return _buildPermissionDenied(context, state);
          }

          if (state is QiblaError) {
            return _buildErrorState(context, state);
          }

          if (state is QiblaSensorUnavailable) {
            return _buildSensorUnavailable(context, state);
          }

          if (state is QiblaLoaded) {
            return _buildLoadedState(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'qibla.loading'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(
    BuildContext context,
    QiblaPermissionDenied state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'qibla.permission_title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'qibla.permission_body'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context.read<QiblaCubit>().retry(),
                  child: Text('common.retry'.tr()),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: Text('qibla.open_settings'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, QiblaError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'errors.generic'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.read<QiblaCubit>().retry(),
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorUnavailable(
    BuildContext context,
    QiblaSensorUnavailable state,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sensors_off, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'qibla.sensor_unavailable'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Static compass showing Qibla direction
          _buildStaticCompass(context, state.qiblaBearing),

          const SizedBox(height: 32),

          // Qibla Info
          _buildQiblaInfo(
            context,
            qiblaBearing: state.qiblaBearing,
            distanceKm: state.distanceKm,
            heading: null,
          ),

          const SizedBox(height: 24),

          // Location source indicator
          _buildLocationSourceBanner(context, state.locationSource),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, QiblaLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Calibration banner
          if (state.needsCalibration) _buildCalibrationBanner(context),

          // Fallback location banner
          if (state.locationSource == LocationSource.fallback)
            _buildLocationSourceBanner(context, state.locationSource),

          const SizedBox(height: 16),

          // Compass with Qibla needle
          _buildAnimatedCompass(context, state),

          const SizedBox(height: 32),

          // Qibla Info Cards
          _buildQiblaInfo(
            context,
            qiblaBearing: state.qiblaBearing,
            distanceKm: state.distanceKm,
            heading: state.heading,
          ),

          const SizedBox(height: 24),

          // Location info
          _buildLocationInfo(context, state),
        ],
      ),
    );
  }

  Widget _buildCalibrationBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.screen_rotation, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'qibla.calibrate'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSourceBanner(
    BuildContext context,
    LocationSource source,
  ) {
    if (source != LocationSource.fallback) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'qibla.using_fallback_location'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCompass(BuildContext context, QiblaLoaded state) {
    final double heading = state.heading ?? 0;
    final double qiblaBearing = state.qiblaBearing;

    // Calculate rotation angles
    final double dialRotation = -heading * (math.pi / 180);
    final double needleRotation = (qiblaBearing - heading) * (math.pi / 180);

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow effect
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Compass dial (rotates with device heading)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: dialRotation, end: dialRotation),
            duration: const Duration(milliseconds: 100),
            builder: (context, value, child) {
              return Transform.rotate(angle: value, child: child);
            },
            child: _buildCompassDial(context),
          ),

          // Qibla needle (points to Qibla relative to dial)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: needleRotation, end: needleRotation),
            duration: const Duration(milliseconds: 100),
            builder: (context, value, child) {
              return Transform.rotate(angle: value, child: child);
            },
            child: _buildQiblaNeedle(context),
          ),

          // Center Kaaba icon
          _buildCenterKaaba(context),
        ],
      ),
    );
  }

  Widget _buildStaticCompass(BuildContext context, double qiblaBearing) {
    final double needleRotation = qiblaBearing * (math.pi / 180);

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass dial (static)
          _buildCompassDial(context),

          // Qibla needle (points to Qibla bearing)
          Transform.rotate(
            angle: needleRotation,
            child: _buildQiblaNeedle(context),
          ),

          // Center Kaaba icon
          _buildCenterKaaba(context),
        ],
      ),
    );
  }

  Widget _buildCompassDial(BuildContext context) {
    return CustomPaint(
      size: const Size(280, 280),
      painter: CompassDialPainter(
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  Widget _buildQiblaNeedle(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(painter: QiblaNeedlePainter()),
    );
  }

  Widget _buildCenterKaaba(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(Icons.mosque, color: AppColors.primary, size: 32),
    );
  }

  Widget _buildQiblaInfo(
    BuildContext context, {
    required double qiblaBearing,
    required double distanceKm,
    required double? heading,
  }) {
    return Row(
      children: [
        // Heading Card
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.explore,
            label: 'qibla.heading'.tr(),
            value: heading != null ? '${heading.round()}°' : '--',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        // Qibla Bearing Card
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.navigation,
            label: 'qibla.qibla_bearing'.tr(),
            value: '${qiblaBearing.round()}°',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context, QiblaLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Distance to Kaaba
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.straighten,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'qibla.distance'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    Text(
                      QiblaUtils.formatDistance(state.distanceKm),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Location source
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getLocationIcon(state.locationSource),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocationSourceLabel(state.locationSource),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    Text(
                      '${state.userLat.toStringAsFixed(4)}, ${state.userLng.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getLocationIcon(LocationSource source) {
    switch (source) {
      case LocationSource.gps:
        return Icons.gps_fixed;
      case LocationSource.settings:
        return Icons.settings;
      case LocationSource.fallback:
        return Icons.location_city;
    }
  }

  String _getLocationSourceLabel(LocationSource source) {
    switch (source) {
      case LocationSource.gps:
        return 'GPS';
      case LocationSource.settings:
        return 'Settings';
      case LocationSource.fallback:
        return 'Cairo (Default)';
    }
  }
}

/// Custom painter for compass dial
class CompassDialPainter extends CustomPainter {
  final bool isDarkMode;

  CompassDialPainter({this.isDarkMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle
    final outerPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius - 5, outerPaint);

    // Inner filled circle
    final innerPaint = Paint()
      ..color = isDarkMode
          ? Colors.grey.shade900.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 10, innerPaint);

    // Degree markers
    final markerPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400
      ..strokeWidth = 1;

    final majorMarkerPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
      ..strokeWidth = 2;

    for (int i = 0; i < 360; i += 5) {
      final isCardinal = i % 90 == 0;
      final isMajor = i % 30 == 0;
      final angle = i * (math.pi / 180);

      final startRadius = radius - (isCardinal ? 30 : (isMajor ? 25 : 18));
      final endRadius = radius - 12;

      final start = Offset(
        center.dx + startRadius * math.sin(angle),
        center.dy - startRadius * math.cos(angle),
      );

      final end = Offset(
        center.dx + endRadius * math.sin(angle),
        center.dy - endRadius * math.cos(angle),
      );

      canvas.drawLine(start, end, isCardinal ? majorMarkerPaint : markerPaint);
    }

    // Cardinal direction labels
    final directions = ['N', 'E', 'S', 'W'];
    final directionColors = [
      Colors.red.shade600,
      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
    ];

    for (int i = 0; i < 4; i++) {
      final angle = i * 90 * (math.pi / 180);
      final textRadius = radius - 50;

      final textSpan = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: directionColors[i],
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final offset = Offset(
        center.dx + textRadius * math.sin(angle) - textPainter.width / 2,
        center.dy - textRadius * math.cos(angle) - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CompassDialPainter oldDelegate) {
    return oldDelegate.isDarkMode != isDarkMode;
  }
}

/// Custom painter for Qibla needle
class QiblaNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Needle pointing up (North by default, rotated to Qibla direction)
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - 90); // Tip
    needlePath.lineTo(center.dx - 12, center.dy - 40); // Left base
    needlePath.lineTo(center.dx, center.dy - 55); // Center notch
    needlePath.lineTo(center.dx + 12, center.dy - 40); // Right base
    needlePath.close();

    // Gradient for needle
    final needlePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.accent, AppColors.accentDark],
          ).createShader(
            Rect.fromCenter(
              center: Offset(center.dx, center.dy - 65),
              width: 30,
              height: 50,
            ),
          )
      ..style = PaintingStyle.fill;

    canvas.drawPath(needlePath, needlePaint);

    // Needle shadow
    final shadowPath = Path();
    shadowPath.moveTo(center.dx, center.dy - 88);
    shadowPath.lineTo(center.dx - 10, center.dy - 42);
    shadowPath.lineTo(center.dx + 10, center.dy - 42);
    shadowPath.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
