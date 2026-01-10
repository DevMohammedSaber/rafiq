import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../cubit/zikr_reader_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:ui' as ui;

class ZikrReaderPage extends StatefulWidget {
  final String categoryId;
  final int? initialIndex;

  const ZikrReaderPage({
    super.key,
    required this.categoryId,
    this.initialIndex,
  });

  @override
  State<ZikrReaderPage> createState() => _ZikrReaderPageState();
}

class _ZikrReaderPageState extends State<ZikrReaderPage> {
  @override
  void initState() {
    super.initState();
    context.read<ZikrReaderCubit>().loadZikrForCategory(
      widget.categoryId,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<ZikrReaderCubit, ZikrReaderState>(
      builder: (context, state) {
        if (state is ZikrReaderInitial) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ZikrReaderLoaded) {
          final zikr = state.currentZikr;
          if (zikr == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('No zikr available')),
            );
          }

          final progress = zikr.repeat > 0
              ? (state.currentCount / zikr.repeat).clamp(0.0, 1.0)
              : 0.0;

          return Scaffold(
            appBar: AppBar(
              title: Text(isRTL ? zikr.titleAr : zikr.titleEn),
              actions: [
                IconButton(
                  icon: Icon(
                    state.isFavorite
                        ? FontAwesomeIcons.solidHeart
                        : FontAwesomeIcons.heart,
                    color: state.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () {
                    context.read<ZikrReaderCubit>().toggleFavorite();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    Share.share(
                      '${zikr.textAr}\n\n${isRTL ? zikr.titleAr : zikr.titleEn}',
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (zikr.repeat > 1)
                            CircularPercentIndicator(
                              radius: 80,
                              lineWidth: 12,
                              percent: progress,
                              center: Text(
                                '${state.currentCount}/${zikr.repeat}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              progressColor: AppColors.primary,
                              backgroundColor: Colors.grey[300]!,
                            ),
                          if (zikr.repeat > 1) const SizedBox(height: 32),
                          Text(
                            zikr.textAr,
                            style: GoogleFonts.amiri(
                              fontSize: 28,
                              height: 2.5,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: ui.TextDirection.rtl,
                          ),
                          if (zikr.sourceAr != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              zikr.sourceAr!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                                fontStyle: FontStyle.italic,
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: state.hasPrevious
                              ? () {
                                  context
                                      .read<ZikrReaderCubit>()
                                      .previousZikr();
                                }
                              : null,
                        ),
                        if (zikr.repeat > 1)
                          ElevatedButton.icon(
                            onPressed: () {
                              context
                                  .read<ZikrReaderCubit>()
                                  .incrementCounter();
                            },
                            icon: const Icon(Icons.add),
                            label: Text("azkar.count".tr()),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        if (zikr.repeat > 1 && state.currentCount > 0)
                          TextButton(
                            onPressed: () {
                              context.read<ZikrReaderCubit>().resetCounter();
                            },
                            child: Text("azkar.reset".tr()),
                          ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: state.hasNext
                              ? () {
                                  context.read<ZikrReaderCubit>().nextZikr();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
