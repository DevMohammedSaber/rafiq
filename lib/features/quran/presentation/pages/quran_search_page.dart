import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../cubit/quran_search_cubit.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/quran_search_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/cubit/settings_cubit.dart';
import 'dart:ui' as ui;

class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Focus the search field on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<QuranSearchCubit>().loadMore();
    }
  }

  void _onSearchChanged(String query) {
    context.read<QuranSearchCubit>().searchDebounced(query);
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<QuranSearchCubit>(),
        child: const _FilterBottomSheet(),
      ),
    );
  }

  void _onResultTap(QuranSearchResult result) {
    // Get current view mode from settings
    final settingsState = context.read<SettingsCubit>().state;
    String viewMode = 'card';
    if (settingsState is SettingsLoaded) {
      viewMode = settingsState.settings.quranSettings.viewMode;
    }

    // Navigate to the ayah with highlight
    final highlightKey = result.ayahKey;

    if (viewMode == 'page' && result.page != null) {
      // For page mode, navigate with page number
      context.push(
        '/quran/${result.surahId}?ayah=${result.ayahNumber}&highlight=$highlightKey&page=${result.page}',
      );
    } else {
      // For card/mushaf mode
      context.push(
        '/quran/${result.surahId}?ayah=${result.ayahNumber}&highlight=$highlightKey',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('quran.search'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
            tooltip: 'quran.filters'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textDirection: ui.TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'quran.search_ayahs'.tr(),
                hintTextDirection: ui.TextDirection.rtl,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<QuranSearchCubit>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Results
          Expanded(
            child: BlocBuilder<QuranSearchCubit, QuranSearchState>(
              builder: (context, state) {
                if (state is QuranSearchInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'quran.search_hint'.tr(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (state is QuranSearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is QuranSearchError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(state.message),
                      ],
                    ),
                  );
                }

                List<QuranSearchResult> results = [];
                bool isLoadingMore = false;
                String query = '';
                bool hasMore = false;

                if (state is QuranSearchLoaded) {
                  results = state.results;
                  query = state.query;
                  hasMore = state.hasMore;
                } else if (state is QuranSearchLoadingMore) {
                  results = state.currentResults;
                  query = state.query;
                  isLoadingMore = true;
                  hasMore = true;
                }

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'quran.no_results'.tr(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Results count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '${'quran.results'.tr()}: ${state is QuranSearchLoaded ? state.totalCount : results.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Results list
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: results.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= results.length) {
                            // Load more indicator
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : TextButton(
                                        onPressed: () => context
                                            .read<QuranSearchCubit>()
                                            .loadMore(),
                                        child: Text('common.load_more'.tr()),
                                      ),
                              ),
                            );
                          }

                          return _SearchResultCard(
                            result: results[index],
                            query: query,
                            onTap: () => _onResultTap(results[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final QuranSearchResult result;
  final String query;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Surah info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${result.surahNameAr} - ${'quran.ayahs'.tr()} ${result.ayahNumber}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ),
                  const Spacer(),
                  if (result.page != null)
                    Text(
                      '${'quran.page_number'.tr()} ${result.page}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Ayah text with highlighting
              _HighlightedText(text: result.text, query: query),

              const SizedBox(height: 8),

              // English surah name
              Text(
                result.surahNameEn,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    // Simple highlighting - find query words in text
    final queryWords = query
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (queryWords.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 18, height: 1.8),
        textDirection: ui.TextDirection.rtl,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    // For now, display the full text
    // In a production app, you'd implement proper Arabic text highlighting
    return Text(
      text,
      style: const TextStyle(fontSize: 18, height: 1.8),
      textDirection: ui.TextDirection.rtl,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet();

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  List<Surah>? _surahs;
  int? _selectedSurahId;
  bool _exactMatch = false;

  @override
  void initState() {
    super.initState();
    _loadSurahs();

    final state = context.read<QuranSearchCubit>().state;
    if (state is QuranSearchLoaded) {
      _selectedSurahId = state.surahFilter;
      _exactMatch = state.exactMatch;
    }
  }

  Future<void> _loadSurahs() async {
    final surahs = await context.read<QuranSearchCubit>().getSurahs();
    if (mounted) {
      setState(() => _surahs = surahs);
    }
  }

  void _applyFilters() {
    final state = context.read<QuranSearchCubit>().state;
    String query = '';
    if (state is QuranSearchLoaded) {
      query = state.query;
    } else if (state is QuranSearchLoadingMore) {
      query = state.query;
    }

    if (query.isNotEmpty) {
      context.read<QuranSearchCubit>().search(
        query,
        surahId: _selectedSurahId,
        exact: _exactMatch,
      );
    }

    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedSurahId = null;
      _exactMatch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'quran.filters'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text('common.clear'.tr()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Surah dropdown
          Text(
            'quran.surah'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          if (_surahs == null)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<int?>(
              value: _selectedSurahId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              hint: Text('quran.all_surahs'.tr()),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('quran.all_surahs'.tr()),
                ),
                ..._surahs!.map(
                  (surah) => DropdownMenuItem<int?>(
                    value: surah.id,
                    child: Text(
                      '${surah.id}. ${surah.nameAr}',
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedSurahId = value);
              },
            ),

          const SizedBox(height: 24),

          // Exact match toggle
          SwitchListTile(
            title: Text('quran.exact_match'.tr()),
            subtitle: Text('quran.exact_match_desc'.tr()),
            value: _exactMatch,
            onChanged: (value) {
              setState(() => _exactMatch = value);
            },
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('common.apply'.tr()),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
