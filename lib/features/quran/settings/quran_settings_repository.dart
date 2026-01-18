import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for Quran-specific settings persistence.
/// Guest users: SharedPreferences
/// Authenticated users: Firestore users/{uid}/settings/quran
class QuranSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _prefKeyFontSize = 'quran_font_size';
  static const String _prefKeyFontFamily = 'quran_font_family';
  static const String _prefKeyReciterId = 'quran_reciter_id';
  static const String _prefKeyLastSurahId = 'quran_last_surah_id';
  static const String _prefKeyLastAyahNumber = 'quran_last_ayah_number';
  static const String _prefKeyLastMushafPage = 'quran_last_mushaf_page';
  static const String _prefKeyViewMode = 'quran_view_mode';
  static const String _prefKeySelectedMushafId = 'quran_selected_mushaf_id';

  bool get _isAuthenticated => _auth.currentUser != null;
  String? get _userId => _auth.currentUser?.uid;

  DocumentReference get _settingsDoc => _firestore
      .collection('users')
      .doc(_userId)
      .collection('settings')
      .doc('quran');

  // Font Size
  Future<double> getFontSize() async {
    if (_isAuthenticated && _userId != null) {
      final doc = await _settingsDoc.get();
      return (doc.data() as Map?)?['fontSize'] as double? ?? 24.0;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_prefKeyFontSize) ?? 24.0;
    }
  }

  Future<void> setFontSize(double size) async {
    if (_isAuthenticated && _userId != null) {
      await _settingsDoc.set({'fontSize': size}, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKeyFontSize, size);
    }
  }

  // Font Family
  Future<String> getFontFamily() async {
    if (_isAuthenticated && _userId != null) {
      final doc = await _settingsDoc.get();
      return (doc.data() as Map?)?['fontFamily'] as String? ?? 'Amiri';
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKeyFontFamily) ?? 'Amiri';
    }
  }

  Future<void> setFontFamily(String family) async {
    if (_isAuthenticated && _userId != null) {
      await _settingsDoc.set({'fontFamily': family}, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyFontFamily, family);
    }
  }

  // Reciter
  Future<String> getReciterId() async {
    if (_isAuthenticated && _userId != null) {
      final doc = await _settingsDoc.get();
      return (doc.data() as Map?)?['reciterId'] as String? ?? 'mishary';
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKeyReciterId) ?? 'mishary';
    }
  }

  Future<void> setReciterId(String id) async {
    if (_isAuthenticated && _userId != null) {
      await _settingsDoc.set({'reciterId': id}, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyReciterId, id);
    }
  }

  // Last Read Position (Text Mode)
  Future<Map<String, int?>> getLastReadPosition() async {
    if (_isAuthenticated && _userId != null) {
      final doc = await _settingsDoc.get();
      final data = doc.data() as Map?;
      return {
        'surahId': data?['lastReadSurahId'] as int?,
        'ayahNumber': data?['lastReadAyahNumber'] as int?,
      };
    } else {
      final prefs = await SharedPreferences.getInstance();
      return {
        'surahId': prefs.getInt(_prefKeyLastSurahId),
        'ayahNumber': prefs.getInt(_prefKeyLastAyahNumber),
      };
    }
  }

  Future<void> setLastReadPosition(int surahId, int ayahNumber) async {
    if (_isAuthenticated && _userId != null) {
      await _settingsDoc.set({
        'lastReadSurahId': surahId,
        'lastReadAyahNumber': ayahNumber,
      }, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyLastSurahId, surahId);
      await prefs.setInt(_prefKeyLastAyahNumber, ayahNumber);
    }
  }

  // Last Read Page (Mushaf Mode)
  Future<int?> getLastMushafPage() async {
    if (_isAuthenticated && _userId != null) {
      final doc = await _settingsDoc.get();
      return (doc.data() as Map?)?['lastMushafPage'] as int?;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_prefKeyLastMushafPage);
    }
  }

  Future<void> setLastMushafPage(int page) async {
    if (_isAuthenticated && _userId != null) {
      await _settingsDoc.set({'lastMushafPage': page}, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyLastMushafPage, page);
    }
  }

  // View Mode (text / mushaf)
  Future<String> getViewMode() async {
    if (_isAuthenticated && _userId != null) {
      final doc = await _settingsDoc.get();
      return (doc.data() as Map?)?['viewMode'] as String? ?? 'text';
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKeyViewMode) ?? 'text';
    }
  }

  Future<void> setViewMode(String mode) async {
    if (_isAuthenticated && _userId != null) {
      await _settingsDoc.set({'viewMode': mode}, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyViewMode, mode);
    }
  }

  // Selected Mushaf ID
  Future<String?> getSelectedMushafId() async {
    if (_isAuthenticated && _userId != null) {
      final doc = await _settingsDoc.get();
      return (doc.data() as Map?)?['selectedMushafId'] as String?;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKeySelectedMushafId);
    }
  }

  Future<void> setSelectedMushafId(String id) async {
    if (_isAuthenticated && _userId != null) {
      await _settingsDoc.set({'selectedMushafId': id}, SetOptions(merge: true));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeySelectedMushafId, id);
    }
  }

  // Load all settings at once
  Future<QuranSettingsData> loadAll() async {
    final fontSize = await getFontSize();
    final fontFamily = await getFontFamily();
    final reciterId = await getReciterId();
    final lastRead = await getLastReadPosition();
    final lastMushafPage = await getLastMushafPage();
    final viewMode = await getViewMode();
    final selectedMushafId = await getSelectedMushafId();

    return QuranSettingsData(
      fontSize: fontSize,
      fontFamily: fontFamily,
      reciterId: reciterId,
      lastReadSurahId: lastRead['surahId'],
      lastReadAyahNumber: lastRead['ayahNumber'],
      lastMushafPage: lastMushafPage,
      viewMode: viewMode,
      selectedMushafId: selectedMushafId,
    );
  }
}

class QuranSettingsData {
  final double fontSize;
  final String fontFamily;
  final String reciterId;
  final int? lastReadSurahId;
  final int? lastReadAyahNumber;
  final int? lastMushafPage;
  final String viewMode;
  final String? selectedMushafId;

  const QuranSettingsData({
    this.fontSize = 24.0,
    this.fontFamily = 'Amiri',
    this.reciterId = 'mishary',
    this.lastReadSurahId,
    this.lastReadAyahNumber,
    this.lastMushafPage,
    this.viewMode = 'text',
    this.selectedMushafId,
  });
}
