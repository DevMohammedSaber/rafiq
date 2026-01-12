import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/components/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/domain/models/user_settings.dart';
import '../../../profile/presentation/cubit/settings_cubit.dart';
import '../../data/prayer_times_service.dart';
import '../../data/prayer_notification_service.dart';

class PrayerSettingsPage extends StatefulWidget {
  const PrayerSettingsPage({super.key});

  @override
  State<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends State<PrayerSettingsPage> {
  late UserSettings _settings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final settingsState = context.read<SettingsCubit>().state;
    if (settingsState is SettingsLoaded) {
      _settings = settingsState.settings;
    } else {
      _settings = const UserSettings();
    }
  }

  void _updateSettings(UserSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  Future<void> _saveAndSchedule() async {
    // Save settings
    await context.read<SettingsCubit>().saveSettings(_settings);

    // Reschedule notifications
    final notificationService = context.read<PrayerNotificationService>();
    await notificationService.reschedule(_settings);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('prayer.settings_saved'.tr())));
      setState(() {
        _hasChanges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('prayer.settings.title'.tr()),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveAndSchedule,
              child: Text(
                'prayer.save_and_schedule'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Location Section
          _buildSectionHeader(context, 'prayer.settings.location_header'.tr()),
          _buildLocationSection(),
          const SizedBox(height: 24),

          // Calculation Method Section
          _buildSectionHeader(
            context,
            'prayer.settings.calculation_header'.tr(),
          ),
          _buildCalculationSection(),
          const SizedBox(height: 24),

          // Reminders Section
          _buildSectionHeader(context, 'prayer.settings.reminders_header'.tr()),
          _buildRemindersSection(),
          const SizedBox(height: 24),

          // Per-Prayer Settings
          _buildSectionHeader(
            context,
            'prayer.settings.per_prayer_header'.tr(),
          ),
          _buildPerPrayerSection(),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveAndSchedule,
              icon: const Icon(Icons.save),
              label: Text('prayer.save_and_schedule'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return AppCard(
      child: Column(
        children: [
          // Current Location Display
          ListTile(
            title: Text('prayer.settings.location'.tr()),
            subtitle: Text(
              '${_settings.location.city}, ${_settings.location.countryCode}',
            ),
            trailing: const Icon(Icons.location_on_outlined),
          ),
          const Divider(height: 1),

          // Use GPS Toggle
          SwitchListTile(
            value: _settings.location.useAutoLocation,
            onChanged: (value) {
              _updateSettings(
                _settings.copyWith(
                  location: _settings.location.copyWith(useAutoLocation: value),
                ),
              );
              if (value) {
                _updateLocationFromGps();
              }
            },
            title: Text('prayer.use_gps'.tr()),
            subtitle: Text('prayer.use_gps_desc'.tr()),
            activeColor: AppColors.primary,
          ),

          // Manual Location (if not using GPS)
          if (!_settings.location.useAutoLocation) ...[
            const Divider(height: 1),
            ListTile(
              title: Text('prayer.manual_location'.tr()),
              subtitle: Text('prayer.tap_to_select'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showLocationPicker,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculationSection() {
    final methods = PrayerTimesService.getAvailableCalculationMethods();
    final asrMethods = PrayerTimesService.getAvailableAsrMethods();

    return AppCard(
      child: Column(
        children: [
          // Calculation Method
          ListTile(
            title: Text('prayer.settings.calculation_authority'.tr()),
            subtitle: Text(
              methods.firstWhere(
                (m) => m['key'] == _settings.prayerSettings.calculationMethod,
                orElse: () => methods.first,
              )['name']!,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCalculationMethodPicker(methods),
          ),
          const Divider(height: 1),

          // Asr Method
          ListTile(
            title: Text('prayer.settings.asr_calculation'.tr()),
            subtitle: Text(
              asrMethods.firstWhere(
                (m) => m['key'] == _settings.prayerSettings.asrMethod,
                orElse: () => asrMethods.first,
              )['name']!,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAsrMethodPicker(asrMethods),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    return AppCard(
      child: Column(
        children: [
          // Enable Reminders Toggle
          SwitchListTile(
            value: _settings.prayerSettings.remindersEnabled,
            onChanged: (value) {
              _updateSettings(
                _settings.copyWith(
                  prayerSettings: _settings.prayerSettings.copyWith(
                    remindersEnabled: value,
                  ),
                ),
              );
            },
            title: Text('prayer.enable_reminders'.tr()),
            activeColor: AppColors.primary,
          ),

          if (_settings.prayerSettings.remindersEnabled) ...[
            const Divider(height: 1),

            // Before Adhan Minutes
            ListTile(
              title: Text('prayer.before_adhan'.tr()),
              trailing: DropdownButton<int>(
                value: _settings.prayerSettings.beforeAdhanMinutes,
                underline: const SizedBox.shrink(),
                items: [0, 5, 10, 15, 20, 30]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          '$v ${v == 0 ? "prayer.off".tr() : "prayer.min".tr()}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(
                      _settings.copyWith(
                        prayerSettings: _settings.prayerSettings.copyWith(
                          beforeAdhanMinutes: value,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const Divider(height: 1),

            // Before Iqama Minutes
            ListTile(
              title: Text('prayer.before_iqama'.tr()),
              trailing: DropdownButton<int>(
                value: _settings.prayerSettings.beforeIqamaMinutes,
                underline: const SizedBox.shrink(),
                items: [0, 2, 5, 10]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          '$v ${v == 0 ? "prayer.off".tr() : "prayer.min".tr()}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(
                      _settings.copyWith(
                        prayerSettings: _settings.prayerSettings.copyWith(
                          beforeIqamaMinutes: value,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerPrayerSection() {
    final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    return Column(
      children: prayers.map((prayer) {
        final perPrayer = _settings.prayerSettings.getPerPrayer(prayer);
        final prayerName = _getLocalizedPrayerName(prayer);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Switch(
                      value: perPrayer.enabled,
                      onChanged: (value) {
                        _updatePerPrayer(
                          prayer,
                          perPrayer.copyWith(enabled: value),
                        );
                      },
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      prayerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: perPrayer.enabled
                            ? null
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
                children: [
                  if (perPrayer.enabled) ...[
                    // Adhan Toggle
                    CheckboxListTile(
                      value: perPrayer.adhanEnabled,
                      onChanged: (value) {
                        _updatePerPrayer(
                          prayer,
                          perPrayer.copyWith(adhanEnabled: value),
                        );
                      },
                      title: Text('prayer.adhan'.tr()),
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // Iqama Toggle
                    CheckboxListTile(
                      value: perPrayer.iqamaEnabled,
                      onChanged: (value) {
                        _updatePerPrayer(
                          prayer,
                          perPrayer.copyWith(iqamaEnabled: value),
                        );
                      },
                      title: Text('prayer.iqama'.tr()),
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // Iqama After Minutes
                    if (perPrayer.iqamaEnabled)
                      ListTile(
                        title: Text('prayer.iqama_after'.tr()),
                        trailing: DropdownButton<int>(
                          value: perPrayer.iqamaAfterMin,
                          underline: const SizedBox.shrink(),
                          items: [5, 10, 15, 20, 25, 30]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v ${"prayer.min".tr()}'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _updatePerPrayer(
                                prayer,
                                perPrayer.copyWith(iqamaAfterMin: value),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _updatePerPrayer(String prayer, PerPrayerSettings settings) {
    _updateSettings(
      _settings.copyWith(
        prayerSettings: _settings.prayerSettings.updatePerPrayer(
          prayer,
          settings,
        ),
      ),
    );
  }

  String _getLocalizedPrayerName(String key) {
    switch (key) {
      case 'fajr':
        return 'prayer.fajr'.tr();
      case 'dhuhr':
        return 'prayer.dhuhr'.tr();
      case 'asr':
        return 'prayer.asr'.tr();
      case 'maghrib':
        return 'prayer.maghrib'.tr();
      case 'isha':
        return 'prayer.isha'.tr();
      default:
        return key;
    }
  }

  Future<void> _updateLocationFromGps() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('prayer.location_error'.tr())),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('prayer.location_error'.tr())));
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get city name from coordinates
      String city = 'Unknown';
      String countryCode = 'EG';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          city =
              placemarks.first.locality ??
              placemarks.first.administrativeArea ??
              'Unknown';
          countryCode = placemarks.first.isoCountryCode ?? 'EG';
        }
      } catch (_) {
        // Geocoding failed, use coordinates
      }

      // Update settings
      _updateSettings(
        _settings.copyWith(
          location: _settings.location.copyWith(
            useAutoLocation: true,
            lat: position.latitude,
            lng: position.longitude,
            city: city,
            countryCode: countryCode,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('prayer.location_error'.tr())));
      }
    }
  }

  void _showLocationPicker() {
    // Show a simple dialog for manual location
    // In a real app, this would be a more sophisticated location picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('prayer.select_location'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Egypt - Cairo (default)
            ListTile(
              title: const Text('Cairo, Egypt'),
              onTap: () {
                _updateSettings(
                  _settings.copyWith(
                    location: _settings.location.copyWith(
                      city: 'Cairo',
                      countryCode: 'EG',
                      lat: 30.0444,
                      lng: 31.2357,
                    ),
                  ),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Alexandria, Egypt'),
              onTap: () {
                _updateSettings(
                  _settings.copyWith(
                    location: _settings.location.copyWith(
                      city: 'Alexandria',
                      countryCode: 'EG',
                      lat: 31.2001,
                      lng: 29.9187,
                    ),
                  ),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Mecca, Saudi Arabia'),
              onTap: () {
                _updateSettings(
                  _settings.copyWith(
                    location: _settings.location.copyWith(
                      city: 'Mecca',
                      countryCode: 'SA',
                      lat: 21.4225,
                      lng: 39.8262,
                    ),
                  ),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Medina, Saudi Arabia'),
              onTap: () {
                _updateSettings(
                  _settings.copyWith(
                    location: _settings.location.copyWith(
                      city: 'Medina',
                      countryCode: 'SA',
                      lat: 24.5247,
                      lng: 39.5692,
                    ),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCalculationMethodPicker(List<Map<String, String>> methods) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('prayer.settings.calculation_authority'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              final isSelected =
                  method['key'] == _settings.prayerSettings.calculationMethod;

              return ListTile(
                title: Text(method['name']!),
                trailing: isSelected
                    ? Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  _updateSettings(
                    _settings.copyWith(
                      prayerSettings: _settings.prayerSettings.copyWith(
                        calculationMethod: method['key'],
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAsrMethodPicker(List<Map<String, String>> methods) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('prayer.settings.asr_calculation'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: methods.map((method) {
            final isSelected =
                method['key'] == _settings.prayerSettings.asrMethod;

            return ListTile(
              title: Text(method['name']!),
              trailing: isSelected
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                _updateSettings(
                  _settings.copyWith(
                    prayerSettings: _settings.prayerSettings.copyWith(
                      asrMethod: method['key'],
                    ),
                  ),
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }
}
