import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/quran_repository.dart';
import '../../data/quran_user_data_repository.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/ayah.dart';
import '../../data/quran_pagination_repository.dart';
import '../../data/mushaf_data_repository.dart';
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

class MushafReaderLoaded extends QuranReaderState {
  final int currentPage;
  final int totalPages;
  final double fontSize;
  final String fontFamily;
  final Set<String> bookmarks;
  final Set<String> favorites;
  final Map<int, List<Ayah>> loadedPages;

  const MushafReaderLoaded({
    required this.currentPage,
    required this.totalPages,
    this.fontSize = 24.0,
    this.fontFamily = 'Amiri',
    this.bookmarks = const {},
    this.favorites = const {},
    this.loadedPages = const {},
  });

  @override
  List<Object?> get props => [
    currentPage,
    totalPages,
    fontSize,
    fontFamily,
    bookmarks,
    favorites,
    loadedPages,
  ];

  MushafReaderLoaded copyWith({
    int? currentPage,
    int? totalPages,
    double? fontSize,
    String? fontFamily,
    Set<String>? bookmarks,
    Set<String>? favorites,
    Map<int, List<Ayah>>? loadedPages,
  }) {
    return MushafReaderLoaded(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      bookmarks: bookmarks ?? this.bookmarks,
      favorites: favorites ?? this.favorites,
      loadedPages: loadedPages ?? this.loadedPages,
    );
  }
}

// Cubit

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final QuranRepository _repository;
  final QuranUserDataRepository _userDataRepository;
  final QuranPaginationRepository _paginationRepository;
  final MushafDataRepository _mushafRepository;
  final SettingsCubit _settingsCubit;

  QuranReaderCubit(
    this._repository,
    this._userDataRepository,
    this._paginationRepository,
    this._mushafRepository,
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

  Future<void> shareAyah(Ayah ayah, {Rect? sharePositionOrigin}) async {
    if (state is! QuranReaderLoaded) return;
    final currentState = state as QuranReaderLoaded;

    final text =
        '${ayah.textAr}\n\n- ${currentState.surah.nameAr} (${ayah.ayahNumber})';
    await Share.share(text, sharePositionOrigin: sharePositionOrigin);
  }

  Future<void> loadMushaf({int? initialPage}) async {
    emit(QuranReaderLoading());
    try {
      await _mushafRepository.loadIndex();
      final totalPages = _mushafRepository.totalPages;
      final bookmarks = await _userDataRepository.listBookmarks();
      final favorites = await _userDataRepository.listFavorites();

      double fontSize = 24.0;
      String fontFamily = 'Amiri';
      int startPage = 1;

      final settingsState = _settingsCubit.state;
      if (settingsState is SettingsLoaded) {
        fontSize = settingsState.settings.quranSettings.fontSize;
        fontFamily = settingsState.settings.quranSettings.fontFamily;
        startPage =
            initialPage ??
            settingsState.settings.quranSettings.lastReadMushafPage ??
            1;
      } else {
        startPage = initialPage ?? 1;
      }

      if (startPage < 1 || startPage > totalPages) {
        startPage = 1;
      }

      final firstPage = await _mushafRepository.getPage(startPage);
      final loadedPages = <int, List<Ayah>>{startPage: firstPage.toAyahs()};

      emit(
        MushafReaderLoaded(
          currentPage: startPage,
          totalPages: totalPages,
          fontSize: fontSize,
          fontFamily: fontFamily,
          bookmarks: bookmarks,
          favorites: favorites,
          loadedPages: loadedPages,
        ),
      );

      _prefetchAdjacentPages(startPage);
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  Future<void> jumpToPage(int pageNumber) async {
    if (state is! MushafReaderLoaded) return;
    final currentState = state as MushafReaderLoaded;

    if (pageNumber < 1 || pageNumber > currentState.totalPages) {
      return;
    }

    try {
      final page = await _mushafRepository.getPage(pageNumber);
      final newLoadedPages = Map<int, List<Ayah>>.from(
        currentState.loadedPages,
      );
      newLoadedPages[pageNumber] = page.toAyahs();

      emit(
        currentState.copyWith(
          currentPage: pageNumber,
          loadedPages: newLoadedPages,
        ),
      );

      _saveLastReadPage(pageNumber);
      _prefetchAdjacentPages(pageNumber);
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  Future<void> jumpToSurah(int surahId) async {
    if (state is! MushafReaderLoaded) return;

    try {
      final page = await _mushafRepository.getFirstPageForSurah(surahId);
      if (page != null) {
        await jumpToPage(page);
      }
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  Future<void> jumpToAyah(int surahId, int ayahNumber) async {
    if (state is! MushafReaderLoaded) return;

    try {
      final page = await _mushafRepository.getPageForAyah(surahId, ayahNumber);
      if (page != null) {
        await jumpToPage(page);
      }
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  Future<void> loadPageIfNeeded(int pageNumber) async {
    if (state is! MushafReaderLoaded) return;
    final currentState = state as MushafReaderLoaded;

    if (currentState.loadedPages.containsKey(pageNumber)) {
      return;
    }

    try {
      final page = await _mushafRepository.getPage(pageNumber);
      final newLoadedPages = Map<int, List<Ayah>>.from(
        currentState.loadedPages,
      );
      newLoadedPages[pageNumber] = page.toAyahs();

      emit(currentState.copyWith(loadedPages: newLoadedPages));
    } catch (e) {
      // Silently fail for background loading
    }
  }

  void _prefetchAdjacentPages(int currentPage) {
    if (currentPage > 1) {
      _mushafRepository.prefetchPage(currentPage - 1);
    }
    if (currentPage < _mushafRepository.totalPages) {
      _mushafRepository.prefetchPage(currentPage + 1);
    }
  }

  void _saveLastReadPage(int pageNumber) {
    final settingsState = _settingsCubit.state;
    if (settingsState is SettingsLoaded) {
      final currentQuranSettings = settingsState.settings.quranSettings;
      final newQuranSettings = currentQuranSettings.copyWith(
        lastReadMushafPage: pageNumber,
      );
      _settingsCubit.saveSettings(
        settingsState.settings.copyWith(quranSettings: newQuranSettings),
        skipNotificationReschedule: true,
      );
    }
  }

  void setMushafFontSize(double fontSize) {
    if (state is! MushafReaderLoaded) return;
    final currentState = state as MushafReaderLoaded;
    emit(currentState.copyWith(fontSize: fontSize));
    _updateQuranSettings(fontSize: fontSize);
  }

  void setMushafFontFamily(String fontFamily) {
    if (state is! MushafReaderLoaded) return;
    final currentState = state as MushafReaderLoaded;
    emit(currentState.copyWith(fontFamily: fontFamily));
    _updateQuranSettings(fontFamily: fontFamily);
  }
}
