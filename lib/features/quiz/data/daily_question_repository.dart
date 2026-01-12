import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../domain/models/quiz_question.dart';
import '../domain/models/daily_question_state.dart';
import 'quiz_repository.dart';

/// Repository for daily question feature
class DailyQuestionRepository {
  final QuizRepository _quizRepository;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache for questions
  List<QuizQuestion>? _questionsCache;

  DailyQuestionRepository({
    QuizRepository? quizRepository,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _quizRepository = quizRepository ?? QuizRepository(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Get today's date key in yyyy-MM-dd format
  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get userId => _auth.currentUser?.uid;

  /// Get today's question (deterministic based on date, only hard questions)
  Future<QuizQuestion> getTodayQuestion() async {
    // Load and cache questions
    _questionsCache ??= await _quizRepository.loadAllQuestions();

    // Filter for difficult questions only
    final hardQuestions = _questionsCache!
        .where((q) => q.difficulty == Difficulty.hard)
        .toList();

    if (hardQuestions.isEmpty) {
      // Fallback to all questions if no hard questions found (should not happen with current data)
      if (_questionsCache!.isEmpty) {
        throw Exception('No questions available');
      }
      final questionIndex = _getQuestionIndexForDay(
        todayKey,
        _questionsCache!.length,
      );
      return _questionsCache![questionIndex];
    }

    // Get deterministic question index based on day key among hard questions
    final questionIndex = _getQuestionIndexForDay(
      todayKey,
      hardQuestions.length,
    );
    return hardQuestions[questionIndex];
  }

  /// Get deterministic question index for a given day
  int _getQuestionIndexForDay(String dayKey, int totalQuestions) {
    // Simple hash function for deterministic selection
    int hash = 0;
    for (int i = 0; i < dayKey.length; i++) {
      hash = (hash * 31 + dayKey.codeUnitAt(i)) % 0x7FFFFFFF;
    }
    return hash % totalQuestions;
  }

  /// Get saved answer state for today
  Future<DailyQuestionState?> getSavedState() async {
    if (isAuthenticated) {
      return _getFirestoreState();
    } else {
      return _getLocalState();
    }
  }

  /// Save answer
  Future<void> saveAnswer({
    required String questionId,
    required DailyQuestionAnswer answer,
    required bool isCorrect,
  }) async {
    final state = DailyQuestionState(
      dayKey: todayKey,
      questionId: questionId,
      type: answer.type,
      selectedIndex: answer.mcqIndex,
      selectedBool: answer.tfValue,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
    );

    if (isAuthenticated) {
      await _saveFirestoreState(state);
    } else {
      await _saveLocalState(state);
    }
  }

  // Local Storage (SharedPreferences) methods

  Future<DailyQuestionState?> _getLocalState() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDay = prefs.getString('daily_q_day');
    if (savedDay == null) return null;

    final questionId = prefs.getString('daily_q_id');
    final type = prefs.getString('daily_q_type') ?? 'mcq';
    final answerStr = prefs.getString('daily_q_answer');
    final isCorrect = prefs.getBool('daily_q_correct') ?? false;
    final answeredAtStr = prefs.getString('daily_q_answered_at');

    int? selectedIndex;
    bool? selectedBool;

    if (type == 'mcq' && answerStr != null) {
      selectedIndex = int.tryParse(answerStr);
    } else if (type == 'tf' && answerStr != null) {
      selectedBool = answerStr.toLowerCase() == 'true';
    }

    return DailyQuestionState(
      dayKey: savedDay,
      questionId: questionId ?? '',
      type: type,
      selectedIndex: selectedIndex,
      selectedBool: selectedBool,
      isCorrect: isCorrect,
      answeredAt: answeredAtStr != null
          ? DateTime.tryParse(answeredAtStr) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Future<void> _saveLocalState(DailyQuestionState state) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('daily_q_day', state.dayKey);
    await prefs.setString('daily_q_id', state.questionId);
    await prefs.setString('daily_q_type', state.type);

    if (state.type == 'mcq' && state.selectedIndex != null) {
      await prefs.setString('daily_q_answer', state.selectedIndex.toString());
    } else if (state.type == 'tf' && state.selectedBool != null) {
      await prefs.setString('daily_q_answer', state.selectedBool.toString());
    }

    await prefs.setBool('daily_q_correct', state.isCorrect);
    await prefs.setString(
      'daily_q_answered_at',
      state.answeredAt.toIso8601String(),
    );
  }

  // Firestore methods

  Future<DailyQuestionState?> _getFirestoreState() async {
    final uid = userId;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['dailyQuestion'] == null) return null;

      return DailyQuestionState.fromJson(
        Map<String, dynamic>.from(data['dailyQuestion']),
      );
    } catch (e) {
      // Fall back to local storage if Firestore fails
      return _getLocalState();
    }
  }

  Future<void> _saveFirestoreState(DailyQuestionState state) async {
    final uid = userId;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).set({
        'dailyQuestion': state.toFirestore(),
      }, SetOptions(merge: true));

      // Also save locally as backup
      await _saveLocalState(state);
    } catch (e) {
      // Fall back to local storage if Firestore fails
      await _saveLocalState(state);
    }
  }

  /// Clear cached questions (for testing)
  void clearCache() {
    _questionsCache = null;
  }
}
