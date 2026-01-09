import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/user_settings.dart';

class UserProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  static const String _kGuestSettingsKey = 'guest_settings';

  UserProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<void> ensureUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      // Create initial doc with default settings
      final defaultSettings = const UserSettings();
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'settings': defaultSettings.toJson(),
      });
    } else {
      // Just update login time
      await docRef.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  Future<UserSettings> loadSettings() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return _loadAuthenticatedSettings(user.uid);
    } else {
      return _loadGuestSettings();
    }
  }

  Future<void> saveSettings(UserSettings settings) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _saveAuthenticatedSettings(user.uid, settings);
    } else {
      await _saveGuestSettings(settings);
    }
  }

  Future<UserSettings> _loadAuthenticatedSettings(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('settings')) {
          return UserSettings.fromJson(
            data['settings'] as Map<String, dynamic>,
          );
        }
      }
      // If no settings found, return default
      return const UserSettings();
    } catch (e) {
      // Fallback
      return const UserSettings();
    }
  }

  Future<void> _saveAuthenticatedSettings(
    String uid,
    UserSettings settings,
  ) async {
    await _firestore.collection('users').doc(uid).set({
      'settings': settings.toJson(),
    }, SetOptions(merge: true));
  }

  Future<UserSettings> _loadGuestSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kGuestSettingsKey);
    if (jsonString != null) {
      try {
        return UserSettings.fromJson(jsonDecode(jsonString));
      } catch (e) {
        return const UserSettings();
      }
    }
    return const UserSettings();
  }

  Future<void> _saveGuestSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGuestSettingsKey, jsonEncode(settings.toJson()));
  }
}
