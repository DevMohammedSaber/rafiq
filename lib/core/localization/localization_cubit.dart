import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationState {
  final Locale locale;
  LocalizationState(this.locale);
}

class LocalizationCubit extends Cubit<LocalizationState> {
  LocalizationCubit() : super(LocalizationState(const Locale('ar'))) {
    _loadLocale();
  }

  static const String _localeKey = 'locale_code';

  void changeLocale(String languageCode) async {
    final locale = Locale(languageCode);
    emit(LocalizationState(locale));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      emit(LocalizationState(Locale(code)));
    }
  }
}
