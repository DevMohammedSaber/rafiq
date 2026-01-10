import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../cubit/hadith_books_cubit.dart';
import '../../../../core/components/app_card.dart';

class HadithBooksPage extends StatefulWidget {
  const HadithBooksPage({super.key});

  @override
  State<HadithBooksPage> createState() => _HadithBooksPageState();
}

class _HadithBooksPageState extends State<HadithBooksPage> {
  @override
  void initState() {
    super.initState();
    context.read<HadithBooksCubit>().loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text("hadith.books".tr()), centerTitle: true),
      body: BlocBuilder<HadithBooksCubit, HadithBooksState>(
        builder: (context, state) {
          if (state is HadithBooksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HadithBooksLoaded) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: state.books.length,
              itemBuilder: (context, index) {
                final book = state.books[index];
                return AppCard(
                  onTap: () => context.push('/hadith/book/${book.id}'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isRTL ? book.titleAr : book.titleEn,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${book.totalCount} ${"hadith.title".tr()}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (state is HadithBooksError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
