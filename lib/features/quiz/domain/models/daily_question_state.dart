import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// State for a saved daily question answer
class DailyQuestionState extends Equatable {
  final String dayKey;
  final String questionId;
  final String type; // "mcq" or "tf"
  final int? selectedIndex; // For MCQ
  final bool? selectedBool; // For TF
  final bool isCorrect;
  final DateTime answeredAt;

  const DailyQuestionState({
    required this.dayKey,
    required this.questionId,
    required this.type,
    this.selectedIndex,
    this.selectedBool,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory DailyQuestionState.fromJson(Map<String, dynamic> json) {
    return DailyQuestionState(
      dayKey: json['dayKey'] as String? ?? json['day'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      type:
          json['type'] as String? ??
          (json['answer'] != null ? json['answer']['type'] as String? : null) ??
          'mcq',
      selectedIndex:
          json['selectedIndex'] as int? ??
          (json['answer'] != null && json['answer']['type'] == 'mcq'
              ? json['answer']['value'] as int?
              : null),
      selectedBool:
          json['selectedBool'] as bool? ??
          (json['answer'] != null && json['answer']['type'] == 'tf'
              ? json['answer']['value'] as bool?
              : null),
      isCorrect: json['isCorrect'] as bool? ?? false,
      answeredAt: json['answeredAt'] != null
          ? (json['answeredAt'] is Timestamp
                ? (json['answeredAt'] as Timestamp).toDate()
                : DateTime.tryParse(json['answeredAt'].toString()) ??
                      DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayKey': dayKey,
      'questionId': questionId,
      'type': type,
      'selectedIndex': selectedIndex,
      'selectedBool': selectedBool,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'day': dayKey,
      'questionId': questionId,
      'answer': {
        'type': type,
        'value': type == 'mcq' ? selectedIndex : selectedBool,
      },
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    dayKey,
    questionId,
    type,
    selectedIndex,
    selectedBool,
    isCorrect,
    answeredAt,
  ];
}

/// Answer for daily question (before saving)
class DailyQuestionAnswer {
  final String type;
  final dynamic value;

  const DailyQuestionAnswer({required this.type, required this.value});

  bool get isMcq => type == 'mcq';
  bool get isTf => type == 'tf';

  int? get mcqIndex => isMcq ? value as int? : null;
  bool? get tfValue => isTf ? value as bool? : null;
}
