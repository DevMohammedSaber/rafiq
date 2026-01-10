import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../cubit/zikr_list_cubit.dart';
import '../../data/azkar_repository.dart';
import '../../domain/models/azkar_category.dart';
import 'dart:ui' as ui;

class ZikrListPage extends StatefulWidget {
  final String categoryId;

  const ZikrListPage({super.key, required this.categoryId});

  @override
  State<ZikrListPage> createState() => _ZikrListPageState();
}

class _ZikrListPageState extends State<ZikrListPage> {
  AZkarCategory? _category;

  @override
  void initState() {
    super.initState();
    context.read<ZikrListCubit>().loadZikrForCategory(widget.categoryId);
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    try {
      final repository = AzkarRepository();
      final categories = await repository.loadCategories();
      final category = categories.firstWhere(
        (cat) => cat.id == widget.categoryId,
        orElse: () => categories.first,
      );
      if (mounted) {
        setState(() {
          _category = category;
        });
      }
    } catch (e) {
      // Category will remain null, fallback to translation key
    }
  }

  String _getCategoryTitle(BuildContext context) {
    if (_category == null) return "azkar.title".tr();
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    return isRTL ? _category!.nameAr : _category!.nameEn;
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<ZikrListCubit, ZikrListState>(
      builder: (context, state) {
        if (state is ZikrListLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(_getCategoryTitle(context))),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ZikrListError) {
          return Scaffold(
            appBar: AppBar(title: Text(_getCategoryTitle(context))),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ZikrListCubit>().loadZikrForCategory(
                        widget.categoryId,
                      );
                    },
                    child: Text("common.retry".tr()),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ZikrListLoaded) {
          return Scaffold(
            appBar: AppBar(title: Text(_getCategoryTitle(context))),
            body: state.zikrList.isEmpty
                ? Center(child: Text("azkar.no_zikr".tr()))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.zikrList.length,
                    itemBuilder: (context, index) {
                      final zikr = state.zikrList[index];
                      final isFavorite = state.favorites.contains(zikr.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          onTap: () {
                            context.push(
                              '/azkar/reader/${widget.categoryId}?index=$index',
                            );
                          },
                          title: Text(
                            isRTL ? zikr.titleAr : zikr.titleEn,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textDirection: ui.TextDirection.rtl,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                zikr.textAr,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textDirection: ui.TextDirection.rtl,
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (zikr.repeat > 1) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "${"azkar.repeat".tr()}: ${zikr.repeat}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? FontAwesomeIcons.solidHeart
                                  : FontAwesomeIcons.heart,
                              color: isFavorite ? Colors.red : null,
                            ),
                            onPressed: () {
                              context.read<ZikrListCubit>().toggleFavorite(
                                zikr.id,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
