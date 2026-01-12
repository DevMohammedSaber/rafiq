import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Quiz category model
class QuizCategory extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final String colorHex;

  const QuizCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.colorHex,
  });

  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    return QuizCategory(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      icon: json['icon'] as String? ?? 'star',
      colorHex: json['color'] as String? ?? '#4CAF50',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon': icon,
      'color': colorHex,
    };
  }

  /// Get localized name
  String getName(String langCode) {
    return langCode == 'ar' ? nameAr : nameEn;
  }

  /// Get color from hex
  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.green;
    }
  }

  /// Get icon data
  IconData get iconData {
    switch (icon) {
      case 'book':
        return Icons.menu_book;
      case 'scroll':
        return Icons.description;
      case 'balance':
        return Icons.balance;
      case 'history':
        return Icons.history_edu;
      case 'star':
      default:
        return Icons.star;
    }
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, icon, colorHex];
}
