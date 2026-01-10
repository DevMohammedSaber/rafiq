import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/hadith_bootstrap_cubit.dart';
import 'hadith_import_page.dart';
import 'hadith_books_page.dart';

class HadithHomePage extends StatelessWidget {
  const HadithHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HadithBootstrapCubit, HadithBootstrapState>(
      builder: (context, state) {
        if (state is BootstrapReady) {
          return const HadithBooksPage();
        } else if (state is BootstrapImporting || state is BootstrapError) {
          return const HadithImportPage();
        } else {
          context.read<HadithBootstrapCubit>().checkStatus();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
