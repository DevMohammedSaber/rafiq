/// Static mapping of Surah ID -> Ayah Number -> Page Number.
/// This is used to populate the [page] column in the [quran_ayahs] table
/// for optimized Mushaf mode lookups.
const Map<int, Map<int, int>> quranPageMap = {
  1: {
    1: 1,
    2: 1,
    3: 1,
    4: 1,
    5: 1,
    6: 1,
    7: 1,
  },
  // Additional surah mappings can be added here
};
