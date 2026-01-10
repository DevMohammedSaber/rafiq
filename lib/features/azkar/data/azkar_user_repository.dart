import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzkarUserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  static const String _kGuestFavoritesKey = 'guest_fav_zikr';

  AzkarUserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<bool> isFavorite(String zikrId) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return _isFavoriteAuthenticated(user.uid, zikrId);
    } else {
      return _isFavoriteGuest(zikrId);
    }
  }

  Future<bool> _isFavoriteAuthenticated(String uid, String zikrId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites_zikr')
          .doc(zikrId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isFavoriteGuest(String zikrId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_kGuestFavoritesKey);
    if (favoritesJson == null) return false;
    try {
      final List<dynamic> favorites = json.decode(favoritesJson);
      return favorites.contains(zikrId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String zikrId) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return _toggleFavoriteAuthenticated(user.uid, zikrId);
    } else {
      return _toggleFavoriteGuest(zikrId);
    }
  }

  Future<bool> _toggleFavoriteAuthenticated(String uid, String zikrId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites_zikr')
          .doc(zikrId);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
        return false;
      } else {
        await docRef.set({
          'zikrId': zikrId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  Future<bool> _toggleFavoriteGuest(String zikrId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_kGuestFavoritesKey);
    List<String> favorites = [];

    if (favoritesJson != null) {
      try {
        final List<dynamic> decoded = json.decode(favoritesJson);
        favorites = decoded.map((e) => e.toString()).toList();
      } catch (e) {
        favorites = [];
      }
    }

    final isFavorite = favorites.contains(zikrId);
    if (isFavorite) {
      favorites.remove(zikrId);
    } else {
      favorites.add(zikrId);
    }

    await prefs.setString(_kGuestFavoritesKey, json.encode(favorites));
    return !isFavorite;
  }

  Future<List<String>> listFavorites() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return _listFavoritesAuthenticated(user.uid);
    } else {
      return _listFavoritesGuest();
    }
  }

  Future<List<String>> _listFavoritesAuthenticated(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites_zikr')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _listFavoritesGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_kGuestFavoritesKey);
    if (favoritesJson == null) return [];

    try {
      final List<dynamic> decoded = json.decode(favoritesJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }
}
