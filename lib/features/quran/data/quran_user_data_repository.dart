import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranUserDataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _guestBookmarksKey = 'guest_bookmarks_ayah';
  static const String _guestFavoritesKey = 'guest_favorites_ayah';

  // Check if user is authenticated (not guest)
  bool get _isAuthenticated => _auth.currentUser != null;
  String? get _userId => _auth.currentUser?.uid;

  // Bookmarks

  Future<void> addBookmarkAyah(int surahId, int ayahNumber) async {
    final key = '$surahId:$ayahNumber';

    if (_isAuthenticated && _userId != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('bookmarks')
          .doc(key)
          .set({
            'type': 'ayah',
            'surahId': surahId,
            'ayahNumber': ayahNumber,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList(_guestBookmarksKey) ?? [];
      if (!bookmarks.contains(key)) {
        bookmarks.add(key);
        await prefs.setStringList(_guestBookmarksKey, bookmarks);
      }
    }
  }

  Future<void> removeBookmarkAyah(int surahId, int ayahNumber) async {
    final key = '$surahId:$ayahNumber';

    if (_isAuthenticated && _userId != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('bookmarks')
          .doc(key)
          .delete();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList(_guestBookmarksKey) ?? [];
      bookmarks.remove(key);
      await prefs.setStringList(_guestBookmarksKey, bookmarks);
    }
  }

  Future<bool> isBookmarked(int surahId, int ayahNumber) async {
    final key = '$surahId:$ayahNumber';

    if (_isAuthenticated && _userId != null) {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('bookmarks')
          .doc(key)
          .get();
      return doc.exists;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList(_guestBookmarksKey) ?? [];
      return bookmarks.contains(key);
    }
  }

  Future<Set<String>> listBookmarks() async {
    if (_isAuthenticated && _userId != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('bookmarks')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList(_guestBookmarksKey) ?? [];
      return bookmarks.toSet();
    }
  }

  // Favorites

  Future<void> addFavoriteAyah(int surahId, int ayahNumber) async {
    final key = '$surahId:$ayahNumber';

    if (_isAuthenticated && _userId != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(key)
          .set({
            'type': 'ayah',
            'surahId': surahId,
            'ayahNumber': ayahNumber,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_guestFavoritesKey) ?? [];
      if (!favorites.contains(key)) {
        favorites.add(key);
        await prefs.setStringList(_guestFavoritesKey, favorites);
      }
    }
  }

  Future<void> removeFavoriteAyah(int surahId, int ayahNumber) async {
    final key = '$surahId:$ayahNumber';

    if (_isAuthenticated && _userId != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(key)
          .delete();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_guestFavoritesKey) ?? [];
      favorites.remove(key);
      await prefs.setStringList(_guestFavoritesKey, favorites);
    }
  }

  Future<bool> isFavorite(int surahId, int ayahNumber) async {
    final key = '$surahId:$ayahNumber';

    if (_isAuthenticated && _userId != null) {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(key)
          .get();
      return doc.exists;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_guestFavoritesKey) ?? [];
      return favorites.contains(key);
    }
  }

  Future<Set<String>> listFavorites() async {
    if (_isAuthenticated && _userId != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_guestFavoritesKey) ?? [];
      return favorites.toSet();
    }
  }

  // Toggle helpers

  Future<bool> toggleBookmark(int surahId, int ayahNumber) async {
    final isCurrentlyBookmarked = await isBookmarked(surahId, ayahNumber);
    if (isCurrentlyBookmarked) {
      await removeBookmarkAyah(surahId, ayahNumber);
      return false;
    } else {
      await addBookmarkAyah(surahId, ayahNumber);
      return true;
    }
  }

  Future<bool> toggleFavorite(int surahId, int ayahNumber) async {
    final isCurrentlyFavorite = await isFavorite(surahId, ayahNumber);
    if (isCurrentlyFavorite) {
      await removeFavoriteAyah(surahId, ayahNumber);
      return false;
    } else {
      await addFavoriteAyah(surahId, ayahNumber);
      return true;
    }
  }
}
