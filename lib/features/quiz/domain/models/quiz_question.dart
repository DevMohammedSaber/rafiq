import 'package:equatable/equatable.dart';

/// Question type enum
enum QuestionType { mcq, trueFalse }

/// Difficulty level enum
enum Difficulty { easy, medium, hard }

/// Quiz question model
class QuizQuestion extends Equatable {
  final String id;
  final String categoryId;
  final QuestionType type;
  final Difficulty difficulty;
  final String questionAr;
  final String questionEn;
  final List<String>? optionsAr;
  final List<String>? optionsEn;
  final int? correctIndex;
  final bool? correctBool;
  final String explanationAr;
  final String explanationEn;

  const QuizQuestion({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.difficulty,
    required this.questionAr,
    required this.questionEn,
    this.optionsAr,
    this.optionsEn,
    this.correctIndex,
    this.correctBool,
    required this.explanationAr,
    required this.explanationEn,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final diffStr = json['difficulty'] as String? ?? 'easy';

    return QuizQuestion(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      type: typeStr == 'tf' ? QuestionType.trueFalse : QuestionType.mcq,
      difficulty: _parseDifficulty(diffStr),
      questionAr: json['question_ar'] as String,
      questionEn: json['question_en'] as String,
      optionsAr: json['options_ar'] != null
          ? List<String>.from(json['options_ar'])
          : null,
      optionsEn: json['options_en'] != null
          ? List<String>.from(json['options_en'])
          : null,
      correctIndex: json['correctIndex'] as int?,
      correctBool: json['correctBool'] as bool?,
      explanationAr: json['explanation_ar'] as String? ?? '',
      explanationEn: json['explanation_en'] as String? ?? '',
    );
  }

  static Difficulty _parseDifficulty(String str) {
    switch (str) {
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      default:
        return Difficulty.easy;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'type': type == QuestionType.trueFalse ? 'tf' : 'mcq',
      'difficulty': difficulty.name,
      'question_ar': questionAr,
      'question_en': questionEn,
      'options_ar': optionsAr,
      'options_en': optionsEn,
      'correctIndex': correctIndex,
      'correctBool': correctBool,
      'explanation_ar': explanationAr,
      'explanation_en': explanationEn,
    };
  }

  /// Get localized question
  String getQuestion(String langCode) {
    return langCode == 'ar' ? questionAr : questionEn;
  }

  /// Get localized options
  List<String> getOptions(String langCode) {
    if (type == QuestionType.trueFalse) {
      return langCode == 'ar' ? ['صحيح', 'خطأ'] : ['True', 'False'];
    }
    return langCode == 'ar' ? (optionsAr ?? []) : (optionsEn ?? []);
  }

  /// Get localized explanation
  String getExplanation(String langCode) {
    return langCode == 'ar' ? explanationAr : explanationEn;
  }

  /// Check if answer is correct
  bool isCorrect(int selectedIndex) {
    if (type == QuestionType.trueFalse) {
      // Index 0 = True, Index 1 = False
      final selectedBool = selectedIndex == 0;
      return selectedBool == correctBool;
    }
    return selectedIndex == correctIndex;
  }

  /// Get correct answer index
  int get correctAnswerIndex {
    if (type == QuestionType.trueFalse) {
      return correctBool == true ? 0 : 1;
    }
    return correctIndex ?? 0;
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    type,
    difficulty,
    questionAr,
    questionEn,
    optionsAr,
    optionsEn,
    correctIndex,
    correctBool,
  ];
}
