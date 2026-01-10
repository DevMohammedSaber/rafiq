import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/azkar_reminder_settings.dart';

class AzkarReminderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  static const String _kGuestRemindersKey = 'guest_azkar_reminders';

  AzkarReminderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<AzkarReminderSettings> loadReminderSettings() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return _loadAuthenticatedSettings(user.uid);
    } else {
      return _loadGuestSettings();
    }
  }

  Future<AzkarReminderSettings> _loadAuthenticatedSettings(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('settings')) {
          final settings = data['settings'] as Map<String, dynamic>;
          if (settings.containsKey('azkarReminders')) {
            return AzkarReminderSettings.fromJson(
              settings['azkarReminders'] as Map<String, dynamic>,
            );
          }
        }
      }
      return const AzkarReminderSettings();
    } catch (e) {
      return const AzkarReminderSettings();
    }
  }

  Future<AzkarReminderSettings> _loadGuestSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kGuestRemindersKey);
    if (jsonString != null) {
      try {
        return AzkarReminderSettings.fromJson(json.decode(jsonString));
      } catch (e) {
        return const AzkarReminderSettings();
      }
    }
    return const AzkarReminderSettings();
  }

  Future<void> saveReminderSettings(AzkarReminderSettings settings) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _saveAuthenticatedSettings(user.uid, settings);
    } else {
      await _saveGuestSettings(settings);
    }
  }

  Future<void> _saveAuthenticatedSettings(
    String uid,
    AzkarReminderSettings settings,
  ) async {
    await _firestore.collection('users').doc(uid).set({
      'settings': {'azkarReminders': settings.toJson()},
    }, SetOptions(merge: true));
  }

  Future<void> _saveGuestSettings(AzkarReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGuestRemindersKey, json.encode(settings.toJson()));
  }
}
