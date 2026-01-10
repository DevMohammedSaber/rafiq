import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HadithUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _guestFavsKey = 'guest_fav_hadith_uids';

  Future<bool> toggleFavorite(String uid, String bookId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites_hadith')
          .doc(uid);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
        return false;
      } else {
        await docRef.set({
          'uid': uid,
          'bookId': bookId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final favs = prefs.getStringList(_guestFavsKey) ?? [];
      if (favs.contains(uid)) {
        favs.remove(uid);
        await prefs.setStringList(_guestFavsKey, favs);
        return false;
      } else {
        favs.add(uid);
        await prefs.setStringList(_guestFavsKey, favs);
        return true;
      }
    }
  }

  Future<Set<String>> listFavorites() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites_hadith')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } else {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_guestFavsKey) ?? []).toSet();
    }
  }
}
