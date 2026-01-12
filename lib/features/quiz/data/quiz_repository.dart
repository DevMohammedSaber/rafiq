import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../domain/models/quiz_category.dart';
import '../domain/models/quiz_question.dart';

/// Repository for loading quiz data from local assets
class QuizRepository {
  static final QuizRepository _instance = QuizRepository._internal();
  factory QuizRepository() => _instance;
  QuizRepository._internal();

  List<QuizCategory>? _categoriesCache;
  List<QuizQuestion>? _questionsCache;
  final Random _random = Random();

  /// Load all categories
  Future<List<QuizCategory>> loadCategories() async {
    if (_categoriesCache != null) return _categoriesCache!;

    final jsonString = await rootBundle.loadString(
      'assets/quiz/categories.json',
    );
    final List<dynamic> jsonList = jsonDecode(jsonString);

    _categoriesCache = jsonList
        .map((json) => QuizCategory.fromJson(json as Map<String, dynamic>))
        .toList();

    return _categoriesCache!;
  }

  /// Load all questions
  Future<List<QuizQuestion>> loadAllQuestions() async {
    if (_questionsCache != null) return _questionsCache!;

    final jsonString = await rootBundle.loadString(
      'assets/quiz/questions.json',
    );
    final List<dynamic> jsonList = jsonDecode(jsonString);

    _questionsCache = jsonList
        .map((json) => QuizQuestion.fromJson(json as Map<String, dynamic>))
        .toList();

    return _questionsCache!;
  }

  /// Load questions for a specific category
  Future<List<QuizQuestion>> loadQuestions(
    String categoryId, {
    int? limit,
  }) async {
    final allQuestions = await loadAllQuestions();

    var filtered = allQuestions
        .where((q) => q.categoryId == categoryId)
        .toList();

    if (limit != null && filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  /// Load random questions for a category (avoids repetition within session)
  Future<List<QuizQuestion>> loadRandomQuestions(
    String categoryId,
    int count, {
    Set<String>? excludeIds,
  }) async {
    final allQuestions = await loadAllQuestions();

    var available = allQuestions
        .where((q) => q.categoryId == categoryId)
        .where((q) => excludeIds == null || !excludeIds.contains(q.id))
        .toList();

    // Shuffle for randomness
    available.shuffle(_random);

    // Take requested count or all available
    final resultCount = count > available.length ? available.length : count;
    return available.take(resultCount).toList();
  }

  /// Load random questions from all categories
  Future<List<QuizQuestion>> loadRandomQuestionsAll(
    int count, {
    Set<String>? excludeIds,
  }) async {
    final allQuestions = await loadAllQuestions();

    var available = allQuestions
        .where((q) => excludeIds == null || !excludeIds.contains(q.id))
        .toList();

    available.shuffle(_random);

    final resultCount = count > available.length ? available.length : count;
    return available.take(resultCount).toList();
  }

  /// Get category by ID
  Future<QuizCategory?> getCategoryById(String categoryId) async {
    final categories = await loadCategories();
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  /// Get question count per category
  Future<Map<String, int>> getQuestionCountByCategory() async {
    final allQuestions = await loadAllQuestions();
    final counts = <String, int>{};

    for (final q in allQuestions) {
      counts[q.categoryId] = (counts[q.categoryId] ?? 0) + 1;
    }

    return counts;
  }

  /// Clear cache (useful for testing or memory management)
  void clearCache() {
    _categoriesCache = null;
    _questionsCache = null;
  }
}
