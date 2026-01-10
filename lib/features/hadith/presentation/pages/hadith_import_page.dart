import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/hadith_bootstrap_cubit.dart';

class HadithImportPage extends StatelessWidget {
  const HadithImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HadithBootstrapCubit, HadithBootstrapState>(
        builder: (context, state) {
          if (state is BootstrapImporting) {
            final progress = state.progress;
            final percent = progress.totalEstimated > 0
                ? progress.inserted / progress.totalEstimated
                : 0.0;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      "hadith.importing".tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${"hadith.importing_book".tr()}: ${progress.bookId}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: progress.totalEstimated > 0 ? percent : null,
                    ),
                    const SizedBox(height: 8),
                    if (progress.totalEstimated > 0)
                      Text("${progress.inserted} / ${progress.totalEstimated}"),
                  ],
                ),
              ),
            );
          }

          if (state is BootstrapError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context
                        .read<HadithBootstrapCubit>()
                        .startImport('plain'),
                    child: Text("common.retry".tr()),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
