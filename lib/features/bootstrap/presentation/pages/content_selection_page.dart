import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/content_selection_cubit.dart';
import '../../../../core/content/models/content_item.dart';

class ContentSelectionPage extends StatefulWidget {
  const ContentSelectionPage({super.key});

  @override
  State<ContentSelectionPage> createState() => _ContentSelectionPageState();
}

class _ContentSelectionPageState extends State<ContentSelectionPage> {
  @override
  void initState() {
    super.initState();
    context.read<ContentSelectionCubit>().loadAvailableContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('content.select_title'.tr()),
        centerTitle: true,
      ),
      body: BlocConsumer<ContentSelectionCubit, ContentSelectionState>(
        listener: (context, state) {
          if (state is ContentSelectionDone) {
            context.go('/home');
          } else if (state is ContentSelectionError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ContentSelectionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ContentSelectionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ContentSelectionCubit>()
                        .loadAvailableContent(),
                    child: Text('content.retry'.tr()),
                  ),
                ],
              ),
            );
          } else if (state is ContentSelectionReady ||
              state is ContentSelectionDownloading) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ContentSelectionState state) {
    final isDownloading = state is ContentSelectionDownloading;
    List<ContentItem> items = [];
    Set<String> selectedIds = {};

    if (state is ContentSelectionReady) {
      items = state.items;
      selectedIds = state.selectedIds;
    } else if (state is ContentSelectionDownloading) {
      items = state.items;
      selectedIds = state.downloadingIds;
    }

    // Group items
    final quranItem = items.firstWhere(
      (i) => i.id == 'quran',
      orElse: () => throw Exception("Quran item missing"),
    );
    final dataItems = items
        .where((i) => !i.id.startsWith('mushaf_') && i.id != 'quran')
        .toList();
    final mushafItems = items.where((i) => i.id.startsWith('mushaf_')).toList();

    return Column(
      children: [
        // Subtitle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'content.select_subtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // 1. Mandatory Quran
              _buildSectionHeader('content.quran_required'.tr()),
              _buildItemTile(
                context,
                quranItem,
                selectedIds,
                isDownloading,
                disabled: true,
              ),

              // 2. Optional Data
              if (dataItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('content.optional'.tr()),
                ...dataItems.map(
                  (item) =>
                      _buildItemTile(context, item, selectedIds, isDownloading),
                ),
              ],

              // 3. Mushafs
              if (mushafItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('quran.mushaf_store'.tr()),
                Card(
                  child: ExpansionTile(
                    title: Text('quran.mushaf_store'.tr()),
                    subtitle: Text(
                      'content.selected_count'.tr(
                        args: [
                          mushafsSelectedCount(
                            mushafItems,
                            selectedIds,
                          ).toString(),
                        ],
                      ),
                    ),
                    children: mushafItems
                        .map(
                          (item) => _buildItemTile(
                            context,
                            item,
                            selectedIds,
                            isDownloading,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('content.total_size'.tr()),
                  Text(
                    'content.unknown_size'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state is ContentSelectionDownloading)
                LinearProgressIndicator(value: state.totalProgress)
              else
                Row(
                  children: [
                    if (quranItem.status == ContentStatus.downloaded)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            context
                                .read<ContentSelectionCubit>()
                                .skipOptional();
                          },
                          child: Text('content.skip_optional'.tr()),
                        ),
                      ),
                    if (quranItem.status == ContentStatus.downloaded)
                      const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: selectedIds.isNotEmpty
                            ? () => context
                                  .read<ContentSelectionCubit>()
                                  .downloadSelected()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('content.download_selected'.tr()),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    ContentItem item,
    Set<String> selectedIds,
    bool isDownloading, {
    bool disabled = false,
  }) {
    final isSelected = selectedIds.contains(item.id);
    final isMandatory = item.isMandatory;

    String subtitle = "";
    if (item.status == ContentStatus.downloaded) {
      if (item.status == ContentStatus.updateAvailable) {
        subtitle = 'content.status_update_available'.tr();
      } else {
        subtitle = 'content.status_installed'.tr();
      }
    } else {
      if (item.sizeBytes != null) {
        subtitle =
            "${(item.sizeBytes! / 1024 / 1024).toStringAsFixed(1)} ${'common.mb'.tr()}";
      }
    }

    return Card(
      elevation: 0,
      color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading:
            isDownloading &&
                isSelected &&
                item.status == ContentStatus.downloading
            ? CircularProgressIndicator(
                value: item.progress > 0 ? item.progress : null,
              )
            : Icon(
                _getIconForType(item.type),
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
        title: Text(
          context.locale.languageCode == 'ar' ? item.titleAr : item.titleEn,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) Text(subtitle),
            if (item.errorMessage != null)
              Text(
                item.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        trailing: isMandatory || disabled
            ? const Icon(Icons.lock, size: 16, color: Colors.grey)
            : Checkbox(
                value: isSelected,
                onChanged: isDownloading
                    ? null
                    : (v) {
                        context.read<ContentSelectionCubit>().toggleSelection(
                          item.id,
                        );
                      },
                activeColor: AppColors.primary,
              ),
        onTap: (isDownloading || isMandatory || disabled)
            ? null
            : () {
                context.read<ContentSelectionCubit>().toggleSelection(item.id);
              },
      ),
    );
  }

  IconData _getIconForType(ContentType type) {
    switch (type) {
      case ContentType.csvSingle:
      case ContentType.csvGroup:
        return Icons.dataset;
      case ContentType.mushafZip:
        return Icons.menu_book;
      case ContentType.json:
        return Icons.quiz;
      default:
        return Icons.article;
    }
  }

  int mushafsSelectedCount(List<ContentItem> items, Set<String> selected) {
    return items.where((i) => selected.contains(i.id)).length;
  }
}
