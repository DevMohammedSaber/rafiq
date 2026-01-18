import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:equatable/equatable.dart';

/// Reciter model for Quran audio
class Reciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String baseUrl;

  const Reciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.baseUrl,
  });
}

/// Audio playback state for UI
class QuranAudioState extends Equatable {
  final bool isPlaying;
  final bool isLoading;
  final int? currentSurah;
  final int? currentAyah;
  final String? currentReciterId;
  final String? error;

  const QuranAudioState({
    this.isPlaying = false,
    this.isLoading = false,
    this.currentSurah,
    this.currentAyah,
    this.currentReciterId,
    this.error,
  });

  QuranAudioState copyWith({
    bool? isPlaying,
    bool? isLoading,
    int? currentSurah,
    int? currentAyah,
    String? currentReciterId,
    String? error,
  }) {
    return QuranAudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentSurah: currentSurah ?? this.currentSurah,
      currentAyah: currentAyah ?? this.currentAyah,
      currentReciterId: currentReciterId ?? this.currentReciterId,
      error: error,
    );
  }

  String get currentAyahKey => currentSurah != null && currentAyah != null
      ? '$currentSurah:$currentAyah'
      : '';

  @override
  List<Object?> get props => [
    isPlaying,
    isLoading,
    currentSurah,
    currentAyah,
    currentReciterId,
    error,
  ];
}

/// Enhanced audio service for Quran ayah playback with state streaming
class QuranAudioPlayerService {
  static final QuranAudioPlayerService instance = QuranAudioPlayerService._();
  QuranAudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  final _stateController = StreamController<QuranAudioState>.broadcast();

  QuranAudioState _currentState = const QuranAudioState();

  // Available reciters (MVP: 2 reciters)
  final List<Reciter> availableReciters = const [
    Reciter(
      id: 'mishary',
      nameAr: 'مشاري العفاسي',
      nameEn: 'Mishary Al-Afasy',
      baseUrl: 'https://everyayah.com/data/Alafasy_128kbps',
    ),
    Reciter(
      id: 'minshawi',
      nameAr: 'المنشاوي (مجود)',
      nameEn: 'Al-Minshawi (Mujawwad)',
      baseUrl: 'https://everyayah.com/data/Minshawy_Mujawwad_192kbps',
    ),
  ];

  Stream<QuranAudioState> get stateStream => _stateController.stream;
  QuranAudioState get currentState => _currentState;
  AudioPlayer get player => _player;

  Reciter get defaultReciter => availableReciters.first;

  Reciter getReciterById(String? id) {
    return availableReciters.firstWhere(
      (e) => e.id == id,
      orElse: () => defaultReciter,
    );
  }

  String _buildAyahUrl(Reciter reciter, int surah, int ayah) {
    final sStr = surah.toString().padLeft(3, '0');
    final aStr = ayah.toString().padLeft(3, '0');
    return '${reciter.baseUrl}/$sStr$aStr.mp3';
  }

  void _updateState(QuranAudioState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Play a specific ayah
  Future<void> playAyah(int surah, int ayah, {String? reciterId}) async {
    try {
      final reciter = getReciterById(reciterId);
      final url = _buildAyahUrl(reciter, surah, ayah);

      print('[QuranAudioPlayer] Playing surah:$surah ayah:$ayah -> $url');

      // First update state to indicate we're loading a NEW ayah
      _updateState(
        QuranAudioState(
          isLoading: true,
          isPlaying: false,
          currentSurah: surah,
          currentAyah: ayah,
          currentReciterId: reciter.id,
        ),
      );

      // Stop any previous playback
      await _player.stop();

      // Small delay to let the stop event flush through
      await Future.delayed(const Duration(milliseconds: 50));

      // Set URL and play
      await _player.setUrl(url);

      // Update state to playing
      _updateState(_currentState.copyWith(isPlaying: true, isLoading: false));

      await _player.play();
    } catch (e) {
      print('[QuranAudioPlayer] Error: $e');
      _updateState(
        _currentState.copyWith(
          isPlaying: false,
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
    _updateState(_currentState.copyWith(isPlaying: false));
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.play();
    _updateState(_currentState.copyWith(isPlaying: true));
  }

  /// Stop playback and clear state
  Future<void> stop() async {
    await _player.stop();
    _updateState(const QuranAudioState());
  }

  /// Check if a specific ayah is currently playing
  bool isAyahPlaying(int surah, int ayah) {
    return _currentState.isPlaying &&
        _currentState.currentSurah == surah &&
        _currentState.currentAyah == ayah;
  }

  /// Check if a specific ayah is the current one (playing or paused)
  bool isCurrentAyah(int surah, int ayah) {
    return _currentState.currentSurah == surah &&
        _currentState.currentAyah == ayah;
  }

  /// Listen to player state changes for auto-advance
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void dispose() {
    _player.dispose();
    _stateController.close();
  }
}
