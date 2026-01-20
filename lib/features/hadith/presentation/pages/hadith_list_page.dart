import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../cubit/hadith_list_cubit.dart';
import '../../../../core/components/app_card.dart';
import 'dart:ui' as ui;

class HadithListPage extends StatefulWidget {
  final String bookId;
  const HadithListPage({super.key, required this.bookId});

  @override
  State<HadithListPage> createState() => _HadithListPageState();
}

class _HadithListPageState extends State<HadithListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HadithListCubit>().loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HadithListCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "hadith.search".tr(),
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) => context.read<HadithListCubit>().search(value),
        ),
      ),
      body: BlocBuilder<HadithListCubit, HadithListState>(
        builder: (context, state) {
          if (state is HadithListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HadithListLoaded) {
            if (state.items.isEmpty) {
              return Center(child: Text("No items found"));
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final item = state.items[index];
                final isFav = state.favorites.contains(item.uid);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => context.push('/hadith/item/${item.uid}'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        item.textAr,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textDirection: ui.TextDirection.rtl,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            if (item.number != null)
                              Text(
                                "#${item.number}",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : null,
                              ),
                              onPressed: () => context
                                  .read<HadithListCubit>()
                                  .toggleFavorite(item.uid),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          if (state is HadithListError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
