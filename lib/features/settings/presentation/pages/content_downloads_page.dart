import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq/core/content/models/content_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/content_manager_cubit.dart';

class ContentDownloadsPage extends StatelessWidget {
  const ContentDownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('content.downloads'.tr())),
      body: BlocProvider(
        create: (context) => ContentManagerCubit()..loadItems(),
        child: BlocBuilder<ContentManagerCubit, ContentManagerState>(
          builder: (context, state) {
            if (state is ContentManagerLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ContentManagerError) {
              return Center(child: Text(state.message));
            } else if (state is ContentManagerLoaded) {
              final items = state.items;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ContentItemTile(item: item);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ContentItemTile extends StatelessWidget {
  final ContentItem item;

  const _ContentItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    bool isDownloading = item.status == ContentStatus.downloading;
    bool isDownloaded =
        item.status == ContentStatus.downloaded ||
        item.status == ContentStatus.updateAvailable;

    return ListTile(
      leading: Icon(
        _getIconForType(item.type),
        size: 32,
        color: isDownloaded ? AppColors.primary : Colors.grey,
      ),
      title: Text(
        context.locale.languageCode == 'ar' ? item.titleAr : item.titleEn,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.status == ContentStatus.downloading)
            Text('content.status_downloading'.tr()),
          if (item.status == ContentStatus.updateAvailable)
            Text(
              'content.status_update_available'.tr(),
              style: TextStyle(color: Colors.amber[800]),
            ),
          if (item.status == ContentStatus.downloaded)
            Text(
              'content.status_installed'.tr(),
              style: const TextStyle(color: Colors.green),
            ),
          if (item.status == ContentStatus.notDownloaded)
            Text('content.status_not_installed'.tr()),

          if (isDownloading) LinearProgressIndicator(value: item.progress),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.status == ContentStatus.notDownloaded ||
              item.status == ContentStatus.updateAvailable)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                context.read<ContentManagerCubit>().downloadItem(item.id);
              },
            ),
          if (item.status == ContentStatus.downloaded && !item.isMandatory)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () {
                // Delete logic
                context.read<ContentManagerCubit>().deleteItem(item.id);
              },
            ),
        ],
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
}
