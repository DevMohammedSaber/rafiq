import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/tasbeeh_preset.dart';

/// Remote repository for syncing Tasbeeh presets with Firestore
class TasbeehRemoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Sync presets to Firestore for authenticated user
  Future<void> syncPresets(String uid, List<TasbeehPreset> presets) async {
    try {
      // Only sync custom presets (non-default)
      final customPresets = presets.where((p) => !p.isDefault).toList();

      await _usersCollection.doc(uid).set({
        'tasbeeh': {
          'presets': customPresets.map((p) => p.toJson()).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail for sync - data is still saved locally
      // In production, consider logging this error
    }
  }

  /// Fetch presets from Firestore for authenticated user
  Future<List<TasbeehPreset>?> fetchPresets(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final tasbeehData = data['tasbeeh'] as Map<String, dynamic>?;
      if (tasbeehData == null) return null;

      final presetsData = tasbeehData['presets'] as List<dynamic>?;
      if (presetsData == null) return null;

      return presetsData
          .map((p) => TasbeehPreset.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Sync stats summary to Firestore (optional for future use)
  Future<void> syncStatsSummary(
    String uid, {
    required int totalCount,
    required int streak,
    required int daysActive,
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'tasbeeh': {
          'stats': {
            'totalCount': totalCount,
            'streak': streak,
            'daysActive': daysActive,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        },
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }
}
