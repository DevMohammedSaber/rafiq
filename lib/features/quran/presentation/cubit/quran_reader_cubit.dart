import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/quran_repository.dart';
import '../../data/quran_user_data_repository.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/ayah.dart';
import '../../data/quran_pagination_repository.dart';
import '../../../profile/presentation/cubit/settings_cubit.dart';

// States

abstract class QuranReaderState extends Equatable {
  const QuranReaderState();
  @override
  List<Object?> get props => [];
}

class QuranReaderInitial extends QuranReaderState {}

class QuranReaderLoading extends QuranReaderState {}

class QuranReaderLoaded extends QuranReaderState {
  final Surah surah;
  final List<Ayah> ayahs;
  final int? activeAyah;
  final double fontSize;
  final String fontFamily;
  final Set<String> bookmarks;
  final Set<String> favorites;
  final Map<int, List<Ayah>>? pages; // Page Number -> List of Ayahs

  const QuranReaderLoaded({
    required this.surah,
    required this.ayahs,
    this.activeAyah,
    this.fontSize = 24.0,
    this.fontFamily = 'Amiri',
    this.bookmarks = const {},
    this.favorites = const {},
    this.pages,
  });

  @override
  List<Object?> get props => [
    surah,
    ayahs,
    activeAyah,
    fontSize,
    fontFamily,
    bookmarks,
    favorites,
    pages,
  ];

  QuranReaderLoaded copyWith({
    Surah? surah,
    List<Ayah>? ayahs,
    int? activeAyah,
    double? fontSize,
    String? fontFamily,
    Set<String>? bookmarks,
    Set<String>? favorites,
    Map<int, List<Ayah>>? pages,
  }) {
    return QuranReaderLoaded(
      surah: surah ?? this.surah,
      ayahs: ayahs ?? this.ayahs,
      activeAyah: activeAyah ?? this.activeAyah,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      bookmarks: bookmarks ?? this.bookmarks,
      favorites: favorites ?? this.favorites,
      pages: pages ?? this.pages,
    );
  }
}

class QuranReaderError extends QuranReaderState {
  final String message;

  const QuranReaderError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final QuranRepository _repository;
  final QuranUserDataRepository _userDataRepository;
  final QuranPaginationRepository _paginationRepository;
  final SettingsCubit _settingsCubit;

  QuranReaderCubit(
    this._repository,
    this._userDataRepository,
    this._paginationRepository,
    this._settingsCubit,
  ) : super(QuranReaderInitial());

  Future<void> loadSurah(int surahId, {int? scrollToAyah}) async {
    emit(QuranReaderLoading());
    try {
      final surah = await _repository.getSurahById(surahId);
      if (surah == null) {
        emit(const QuranReaderError('Surah not found'));
        return;
      }

      final ayahs = await _repository.loadAyahs(surahId);

      // Group Ayahs by page
      final pages = <int, List<Ayah>>{};
      for (final ayah in ayahs) {
        final pageNum = await _paginationRepository.getPageForAyah(
          ayah.surahId,
          ayah.ayahNumber,
        );
        if (!pages.containsKey(pageNum)) {
          pages[pageNum] = [];
        }
        pages[pageNum]!.add(ayah);
      }

      final bookmarks = await _userDataRepository.listBookmarks();
      final favorites = await _userDataRepository.listFavorites();

      // Get current settings
      double fontSize = 24.0;
      String fontFamily = 'Amiri';

      final settingsState = _settingsCubit.state;
      if (settingsState is SettingsLoaded) {
        fontSize = settingsState.settings.quranSettings.fontSize;
        fontFamily = settingsState.settings.quranSettings.fontFamily;
      }

      emit(
        QuranReaderLoaded(
          surah: surah,
          ayahs: ayahs,
          activeAyah: scrollToAyah,
          fontSize: fontSize,
          fontFamily: fontFamily,
          bookmarks: bookmarks,
          favorites: favorites,
          pages: pages,
        ),
      );
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  void setFontSize(double fontSize) {
    if (state is! QuranReaderLoaded) return;
    final currentState = state as QuranReaderLoaded;
    emit(currentState.copyWith(fontSize: fontSize));

    // Save to settings
    _updateQuranSettings(fontSize: fontSize);
  }

  void setFontFamily(String fontFamily) {
    if (state is! QuranReaderLoaded) return;
    final currentState = state as QuranReaderLoaded;
    emit(currentState.copyWith(fontFamily: fontFamily));

    // Save to settings
    _updateQuranSettings(fontFamily: fontFamily);
  }

  void _updateQuranSettings({double? fontSize, String? fontFamily}) {
    final settingsState = _settingsCubit.state;
    if (settingsState is SettingsLoaded) {
      final currentQuranSettings = settingsState.settings.quranSettings;
      final newQuranSettings = currentQuranSettings.copyWith(
        fontSize: fontSize,
        fontFamily: fontFamily,
      );
      final newSettings = settingsState.settings.copyWith(
        quranSettings: newQuranSettings,
      );

      // Use optimistic update first to avoid loading state flicker
      _settingsCubit.updateSettings(newSettings);

      // Then save in background (this will emit loading, but UI already updated)
      _settingsCubit.saveSettings(
        newSettings,
        skipNotificationReschedule: true,
      );
    }
  }

  Future<void> toggleBookmark(Ayah ayah) async {
    if (state is! QuranReaderLoaded) return;
    final currentState = state as QuranReaderLoaded;

    final isNowBookmarked = await _userDataRepository.toggleBookmark(
      ayah.surahId,
      ayah.ayahNumber,
    );

    final newBookmarks = Set<String>.from(currentState.bookmarks);
    if (isNowBookmarked) {
      newBookmarks.add(ayah.key);
    } else {
      newBookmarks.remove(ayah.key);
    }

    emit(currentState.copyWith(bookmarks: newBookmarks));
  }

  Future<void> toggleFavorite(Ayah ayah) async {
    if (state is! QuranReaderLoaded) return;
    final currentState = state as QuranReaderLoaded;

    final isNowFavorite = await _userDataRepository.toggleFavorite(
      ayah.surahId,
      ayah.ayahNumber,
    );

    final newFavorites = Set<String>.from(currentState.favorites);
    if (isNowFavorite) {
      newFavorites.add(ayah.key);
    } else {
      newFavorites.remove(ayah.key);
    }

    emit(currentState.copyWith(favorites: newFavorites));
  }

  void setLastRead(Ayah ayah) {
    if (state is! QuranReaderLoaded) return;
    final currentState = state as QuranReaderLoaded;

    emit(currentState.copyWith(activeAyah: ayah.ayahNumber));

    // Save to settings without triggering notification rescheduling
    final settingsState = _settingsCubit.state;
    if (settingsState is SettingsLoaded) {
      final currentQuranSettings = settingsState.settings.quranSettings;
      final newQuranSettings = currentQuranSettings.copyWith(
        lastReadSurahId: ayah.surahId,
        lastReadAyahNumber: ayah.ayahNumber,
      );
      _settingsCubit.saveSettings(
        settingsState.settings.copyWith(quranSettings: newQuranSettings),
        skipNotificationReschedule: true,
      );
    }
  }

  Future<void> shareAyah(Ayah ayah) async {
    if (state is! QuranReaderLoaded) return;
    final currentState = state as QuranReaderLoaded;

    final text =
        '${ayah.textAr}\\n\\n- ${currentState.surah.nameAr} (${ayah.ayahNumber})';
    await Share.share(text);
  }
}
