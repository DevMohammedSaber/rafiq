import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../hadith/presentation/cubit/hadith_of_day_cubit.dart';
import '../../../core/components/app_card.dart';
import 'dart:ui' as ui;

class HadithOfDayCard extends StatefulWidget {
  const HadithOfDayCard({super.key});

  @override
  State<HadithOfDayCard> createState() => _HadithOfDayCardState();
}

class _HadithOfDayCardState extends State<HadithOfDayCard> {
  @override
  void initState() {
    super.initState();
    context.read<HadithOfDayCubit>().loadToday();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HadithOfDayCubit, HadithOfDayState>(
      builder: (context, state) {
        if (state is HadithOfDayLoaded) {
          final item = state.item;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "hadith.of_the_day".tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => context.push('/hadith/item/${item.uid}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item.textAr,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textDirection: ui.TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "hadith.goto".tr(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
