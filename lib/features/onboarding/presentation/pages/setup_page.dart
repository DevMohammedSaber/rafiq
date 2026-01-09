import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:rafiq/features/profile/presentation/cubit/settings_cubit.dart';
import 'package:rafiq/features/profile/domain/models/user_settings.dart';
import 'package:rafiq/core/components/primary_button.dart';
import 'package:rafiq/features/prayer/data/prayer_notification_service.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int _currentStep = 0;
  final TextEditingController _cityController = TextEditingController(
    text: "Cairo",
  );

  // Local state for Step 2
  bool _remindersEnabled = true;
  int _beforeAdhan = 10;

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("setup.step${_currentStep + 1}_title".tr()),
        centerTitle: true,
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded && state.settings.setupDone) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsLoaded) {
            return Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildLocationStep(state.settings),
                      _buildPrayerStep(state.settings),
                      _buildPermissionsStep(state.settings),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: () => setState(() => _currentStep--),
                          child: const Text("Back"),
                        ),
                      const Spacer(),
                      Expanded(
                        child: PrimaryButton(
                          text: _currentStep == 2 ? "setup.finish".tr() : "Next",
                          onPressed: () => _onNext(state.settings),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Future<void> _onNext(UserSettings settings) async {
    if (_currentStep < 2) {
      if (_currentStep == 1) {
        // Save intermediate prayer changes
        final newPrayerSettings = settings.prayerSettings.copyWith(
          beforeAdhanMinutes: _beforeAdhan,
          enabledPrayers: settings.prayerSettings.enabledPrayers.map(
            (k, v) => MapEntry(k, _remindersEnabled),
          ),
        );
        context.read<SettingsCubit>().updatePrayerSettings(newPrayerSettings);
      }
      setState(() => _currentStep++);
    } else {
      // Finish
      await context.read<SettingsCubit>().saveSettings(
        settings,
        finishSetup: true,
      );
    }
  }

  // STEP 1: Location
  Widget _buildLocationStep(UserSettings settings) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          PrimaryButton(
            text: "setup.use_gps".tr(),
            onPressed: () async {
              await _useGps();
            },
          ),
          const SizedBox(height: 24),
          Text(
            "setup.select_manual".tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: "setup.city".tr(),
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              context.read<SettingsCubit>().updateLocation(
                settings.location.copyWith(city: val, useAutoLocation: false),
              );
            },
          ),
          const SizedBox(height: 16),
          // Country Dropdown mock
          DropdownButtonFormField<String>(
            initialValue: "EG",
            items: const [DropdownMenuItem(value: "EG", child: Text("Egypt"))],
            onChanged: (val) {},
            decoration: InputDecoration(
              labelText: "setup.country".tr(),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useGps() async {
    // Basic geolocator logic
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        context.read<SettingsCubit>().updateLocation(
          UserLocation(
            useAutoLocation: true,
            lat: position.latitude,
            lng: position.longitude,
            city: pm.locality ?? "Unknown",
            countryCode: pm.isoCountryCode ?? "EG",
          ),
        );
        _cityController.text = pm.locality ?? "";
      }
    } catch (e) {
      // Handle error
    }
  }

  // STEP 2: Prayer Settings
  Widget _buildPrayerStep(UserSettings settings) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SwitchListTile(
            title: Text("setup.enable_reminders".tr()),
            value: _remindersEnabled,
            onChanged: (val) => setState(() => _remindersEnabled = val),
          ),
          const SizedBox(height: 16),
          Text("setup.before_adhan".tr()),
          Slider(
            value: _beforeAdhan.toDouble(),
            min: 0,
            max: 30,
            divisions: 6,
            label: "$_beforeAdhan min",
            onChanged: (val) => setState(() => _beforeAdhan = val.round()),
          ),
        ],
      ),
    );
  }

  // STEP 3: Permissions
  Widget _buildPermissionsStep(UserSettings settings) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "setup.perm_desc".tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: "setup.allow_notifs".tr(),
            onPressed: () async {
              // Awesome Notifications handles its own permissions
              await context
                  .read<PrayerNotificationService>()
                  .requestPermissions();
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            child: Text("setup.allow_location".tr()),
            onPressed: () async {
              await Permission.location.request();
            },
          ),
        ],
      ),
    );
  }
}
