import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../cubit/quran_home_cubit.dart';
import '../../domain/models/surah.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:ui' as ui;

class QuranHomePage extends StatefulWidget {
  const QuranHomePage({super.key});

  @override
  State<QuranHomePage> createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<QuranHomeCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("quran.title".tr())),
      body: Column(
        children: [
          // Search bars
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<QuranHomeCubit, QuranHomeState>(
              builder: (context, state) {
                final query = state is QuranHomeLoaded ? state.query : '';
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "quran.search".tr(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<QuranHomeCubit>().clearQuery();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    context.read<QuranHomeCubit>().setQuery(value);
                  },
                );
              },
            ),
          ),

          // Surah list
          Expanded(
            child: BlocBuilder<QuranHomeCubit, QuranHomeState>(
              builder: (context, state) {
                if (state is QuranHomeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is QuranHomeError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<QuranHomeCubit>().load(),
                          child: Text("common.retry".tr()),
                        ),
                      ],
                    ),
                  );
                }

                if (state is QuranHomeLoaded) {
                  if (state.filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.magnifyingGlass,
                            size: 48,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text("quran.no_results".tr()),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.filtered.length,
                    itemBuilder: (context, index) {
                      final surah = state.filtered[index];
                      return _SurahCard(surah: surah);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  final Surah surah;

  const _SurahCard({required this.surah});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          context.push('/quran/${surah.id}');
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              surah.id.toString(),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          surah.nameAr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textDirection: ui.TextDirection.rtl,
        ),
        subtitle: Text(
          '${surah.nameEn} - ${surah.ayahCount} ${"quran.ayahs".tr()}',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              surah.type == 'Makkiyah'
                  ? "quran.Makkiyah".tr()
                  : "quran.Madaniyah".tr(),
              style: TextStyle(
                fontSize: 12,
                color: surah.type == 'Makkiyah' ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
