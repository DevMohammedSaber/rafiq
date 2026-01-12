import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/user_profile.dart';

/// Repository for managing user profile data
class ProfileRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _guestNameKey = 'guest_name';
  static const String _guestProfileKey = 'guest_profile';

  /// Get Firestore users collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Load the current user profile
  Future<UserProfile> loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      // Guest user - load from SharedPreferences
      return await _loadGuestProfile();
    }

    // Authenticated user - load from Firestore with fallback to Auth data
    return await _loadAuthProfile(user);
  }

  /// Load guest profile from SharedPreferences
  Future<UserProfile> _loadGuestProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final guestName = prefs.getString(_guestNameKey) ?? 'Guest';
    final profileJson = prefs.getString(_guestProfileKey);

    if (profileJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(profileJson);
        return UserProfile.fromJson(decoded);
      } catch (_) {
        // Fall back to default guest profile
      }
    }

    return UserProfile.guest(name: guestName);
  }

  /// Load authenticated user profile from Firestore
  Future<UserProfile> _loadAuthProfile(User user) async {
    try {
      final doc = await _usersCollection.doc(user.uid).get();
      Map<String, dynamic>? firestoreData;

      if (doc.exists) {
        firestoreData = doc.data();
      }

      // Determine provider
      String? provider;
      if (user.providerData.isNotEmpty) {
        final providerId = user.providerData.first.providerId;
        if (providerId.contains('google')) {
          provider = 'google';
        } else if (providerId.contains('apple')) {
          provider = 'apple';
        }
      }

      return UserProfile.fromFirebaseUser(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
        provider: provider,
        firestoreData: firestoreData,
      );
    } catch (e) {
      // Fallback to basic Auth data
      return UserProfile(
        uid: user.uid,
        name: user.displayName ?? 'User',
        email: user.email,
        photoUrl: user.photoURL,
        isGuest: false,
      );
    }
  }

  /// Update profile name
  Future<void> updateProfileName(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      // Guest - save to SharedPreferences
      await _updateGuestName(name);
    } else {
      // Auth user - update both Firebase Auth and Firestore
      await _updateAuthName(user.uid, name);
    }
  }

  /// Update guest name in SharedPreferences
  Future<void> _updateGuestName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestNameKey, name);

    // Also update the profile JSON
    final profileJson = prefs.getString(_guestProfileKey);
    if (profileJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(profileJson);
        decoded['name'] = name;
        await prefs.setString(_guestProfileKey, jsonEncode(decoded));
      } catch (_) {
        // Create new profile
        final profile = UserProfile.guest(name: name);
        await prefs.setString(_guestProfileKey, jsonEncode(profile.toJson()));
      }
    } else {
      final profile = UserProfile.guest(name: name);
      await prefs.setString(_guestProfileKey, jsonEncode(profile.toJson()));
    }
  }

  /// Update auth user name in Firebase Auth and Firestore
  Future<void> _updateAuthName(String uid, String name) async {
    // Update Firebase Auth
    await _auth.currentUser?.updateDisplayName(name);

    // Update Firestore
    await _usersCollection.doc(uid).set({
      'name': name,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update profile bio
  Future<void> updateProfileBio(String bio) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _usersCollection.doc(user.uid).set({
      'profile': {'bio': bio},
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Create or update Firestore user document
  Future<void> createOrUpdateUserDocument(UserProfile profile) async {
    if (profile.uid == null) return;

    final docRef = _usersCollection.doc(profile.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Create new document
      await docRef.set({
        'name': profile.name,
        'email': profile.email,
        'photoUrl': profile.photoUrl,
        'provider': profile.provider,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'profile': {'bio': profile.bio, 'countryCode': profile.countryCode},
      });
    } else {
      // Update existing document
      await docRef.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  /// Delete the current user account
  /// Throws if re-authentication is required
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    try {
      // Delete Firestore document first
      await _usersCollection.doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('requires-recent-login');
      }
      rethrow;
    }
  }

  /// Clear guest data from SharedPreferences
  Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestNameKey);
    await prefs.remove(_guestProfileKey);
  }

  /// Check if current user is guest
  bool get isGuest => _auth.currentUser == null;

  /// Get current user ID (null for guest)
  String? get currentUserId => _auth.currentUser?.uid;
}
