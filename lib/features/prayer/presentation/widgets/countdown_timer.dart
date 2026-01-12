import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CountdownTimer extends StatelessWidget {
  final Duration duration;
  final Color? textColor;
  final TextStyle? textStyle;

  const CountdownTimer({
    super.key,
    required this.duration,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final parts = <String>[];

    if (hours > 0) {
      parts.add('$hours ${_getHoursLabel(hours)}');
    }
    if (minutes > 0 || hours > 0) {
      parts.add('$minutes ${_getMinutesLabel(minutes)}');
    }
    parts.add('$seconds ${_getSecondsLabel(seconds)}');

    // Format for display
    final displayText = _formatCountdown(hours, minutes, seconds);

    return Column(
      children: [
        Text(
          'prayer.countdown'.tr(),
          style:
              textStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    textColor?.withValues(alpha: 0.7) ??
                    Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          displayText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String _formatCountdown(int hours, int minutes, int seconds) {
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getHoursLabel(int value) {
    return value == 1 ? 'h' : 'h';
  }

  String _getMinutesLabel(int value) {
    return value == 1 ? 'm' : 'm';
  }

  String _getSecondsLabel(int value) {
    return value == 1 ? 's' : 's';
  }
}
