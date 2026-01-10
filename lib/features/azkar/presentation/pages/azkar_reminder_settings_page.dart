import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/azkar_reminder_cubit.dart';
import '../../domain/models/azkar_reminder_settings.dart';

class AzkarReminderSettingsPage extends StatefulWidget {
  const AzkarReminderSettingsPage({super.key});

  @override
  State<AzkarReminderSettingsPage> createState() =>
      _AzkarReminderSettingsPageState();
}

class _AzkarReminderSettingsPageState extends State<AzkarReminderSettingsPage> {
  bool _enabledMorning = false;
  bool _enabledEvening = false;
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    context.read<AzkarReminderCubit>().loadReminderSettings();
  }

  Future<void> _selectTime(BuildContext context, bool isMorning) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMorning ? _morningTime : _eveningTime,
    );
    if (picked != null) {
      setState(() {
        if (isMorning) {
          _morningTime = picked;
        } else {
          _eveningTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("azkar.reminders".tr())),
      body: BlocConsumer<AzkarReminderCubit, AzkarReminderState>(
        listener: (context, state) {
          if (state is AzkarReminderLoaded) {
            setState(() {
              _enabledMorning = state.settings.enabledMorning;
              _enabledEvening = state.settings.enabledEvening;
              final morningParts = state.settings.morningTime.split(':');
              _morningTime = TimeOfDay(
                hour: int.parse(morningParts[0]),
                minute: int.parse(morningParts[1]),
              );
              final eveningParts = state.settings.eveningTime.split(':');
              _eveningTime = TimeOfDay(
                hour: int.parse(eveningParts[0]),
                minute: int.parse(eveningParts[1]),
              );
            });
          }
        },
        builder: (context, state) {
          if (state is AzkarReminderLoading && _enabledMorning == false) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text("azkar.enable_morning".tr()),
                  value: _enabledMorning,
                  onChanged: (value) {
                    setState(() {
                      _enabledMorning = value;
                    });
                  },
                ),
                if (_enabledMorning)
                  ListTile(
                    title: Text("azkar.morning_time".tr()),
                    trailing: TextButton(
                      onPressed: () => _selectTime(context, true),
                      child: Text(_formatTime(_morningTime)),
                    ),
                  ),
                const Divider(),
                SwitchListTile(
                  title: Text("azkar.enable_evening".tr()),
                  value: _enabledEvening,
                  onChanged: (value) {
                    setState(() {
                      _enabledEvening = value;
                    });
                  },
                ),
                if (_enabledEvening)
                  ListTile(
                    title: Text("azkar.evening_time".tr()),
                    trailing: TextButton(
                      onPressed: () => _selectTime(context, false),
                      child: Text(_formatTime(_eveningTime)),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final settings = AzkarReminderSettings(
                        enabledMorning: _enabledMorning,
                        enabledEvening: _enabledEvening,
                        morningTime: _formatTime(_morningTime),
                        eveningTime: _formatTime(_eveningTime),
                      );
                      context.read<AzkarReminderCubit>().saveReminderSettings(
                        settings,
                      );
                    },
                    child: Text("common.save".tr()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
