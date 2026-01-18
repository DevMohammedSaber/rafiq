import 'package:just_audio/just_audio.dart';

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

class QuranAyahAudioService {
  static final QuranAyahAudioService instance = QuranAyahAudioService._();
  QuranAyahAudioService._();

  final AudioPlayer _player = AudioPlayer();

  // Can be moved to a configuration file or fetched
  final List<Reciter> availableReciters = [
    const Reciter(
      id: "mishary",
      nameAr: "مشاري العفاسي",
      nameEn: "Mishary Al-Afasy",
      baseUrl: "https://everyayah.com/data/Alafasy_128kbps",
    ),
    const Reciter(
      id: "minshawi",
      nameAr: "المنشاوي (مجود)",
      nameEn: "Al-Minshawi (Mujawwad)",
      baseUrl: "https://everyayah.com/data/Minshawy_Mujawwad_192kbps",
    ),
  ];

  Reciter get defaultReciter => availableReciters.first;

  Reciter getReciterById(String? id) {
    return availableReciters.firstWhere(
      (e) => e.id == id,
      orElse: () => defaultReciter,
    );
  }

  String buildAyahUrl(Reciter reciter, int surah, int ayah) {
    // pattern: 001001.mp3
    final sStr = surah.toString().padLeft(3, '0');
    final aStr = ayah.toString().padLeft(3, '0');
    return "${reciter.baseUrl}/$sStr$aStr.mp3";
  }

  Future<void> playAyah(int surah, int ayah, {String? reciterId}) async {
    try {
      final reciter = getReciterById(reciterId);
      final url = buildAyahUrl(reciter, surah, ayah);

      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      print("Error playing ayah audio: $e");
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Expose player to check processing state if needed
  AudioPlayer get player => _player;
}
