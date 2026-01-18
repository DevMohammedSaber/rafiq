import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/tafsir_cubit.dart';
import '../../domain/models/tafsir_package.dart';
import '../../../../../core/theme/app_colors.dart';
import 'dart:ui' as ui;

class TafsirPage extends StatefulWidget {
  final int surahId;
  final int ayahNumber;
  final String ayahText;

  const TafsirPage({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  State<TafsirPage> createState() => _TafsirPageState();
}

class _TafsirPageState extends State<TafsirPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<TafsirCubit>().loadForAyah(
      widget.surahId,
      widget.ayahNumber,
      widget.ayahText,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('quran.tafsir'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'quran.tafsir'.tr()),
            Tab(text: 'quran.translation'.tr()),
          ],
        ),
      ),
      body: BlocBuilder<TafsirCubit, TafsirState>(
        builder: (context, state) {
          if (state is TafsirLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TafsirError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message),
                ],
              ),
            );
          }

          if (state is TafsirLoaded) {
            return Column(
              children: [
                // Ayah text at top
                _AyahHeader(
                  surahId: state.surahId,
                  ayahNumber: state.ayahNumber,
                  ayahText: state.ayahText,
                ),
                // Tabs content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _PackagesListView(
                        packages: state.tafsirPackages,
                        downloadStatus: state.downloadStatus,
                        loadedContent: state.loadedTafsir,
                        selectedPackageId: state.selectedPackageId,
                        downloadingPackageId: state.downloadingPackageId,
                        downloadProgress: state.downloadProgress,
                      ),
                      _PackagesListView(
                        packages: state.translationPackages,
                        downloadStatus: state.downloadStatus,
                        loadedContent: state.loadedTafsir,
                        selectedPackageId: state.selectedPackageId,
                        downloadingPackageId: state.downloadingPackageId,
                        downloadProgress: state.downloadProgress,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AyahHeader extends StatelessWidget {
  final int surahId;
  final int ayahNumber;
  final String ayahText;

  const _AyahHeader({
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            ayahText,
            style: const TextStyle(fontSize: 20, height: 2.0),
            textAlign: TextAlign.center,
            textDirection: ui.TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            '${'quran.surah'.tr()} $surahId - ${'quran.ayahs'.tr()} $ayahNumber',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PackagesListView extends StatelessWidget {
  final List<TafsirPackage> packages;
  final Map<String, bool> downloadStatus;
  final Map<String, String?> loadedContent;
  final String? selectedPackageId;
  final String? downloadingPackageId;
  final double downloadProgress;

  const _PackagesListView({
    required this.packages,
    required this.downloadStatus,
    required this.loadedContent,
    this.selectedPackageId,
    this.downloadingPackageId,
    this.downloadProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined, size: 48),
            const SizedBox(height: 16),
            Text('quran.no_packages'.tr()),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        final isDownloaded = downloadStatus[package.id] ?? false;
        final isDownloading = downloadingPackageId == package.id;
        final isSelected = selectedPackageId == package.id;
        final content = loadedContent[package.id];

        return _PackageCard(
          package: package,
          isDownloaded: isDownloaded,
          isDownloading: isDownloading,
          isSelected: isSelected,
          downloadProgress: isDownloading ? downloadProgress : 0.0,
          content: content,
        );
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  final TafsirPackage package;
  final bool isDownloaded;
  final bool isDownloading;
  final bool isSelected;
  final double downloadProgress;
  final String? content;

  const _PackageCard({
    required this.package,
    required this.isDownloaded,
    required this.isDownloading,
    required this.isSelected,
    required this.downloadProgress,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isDownloaded
            ? () => context.read<TafsirCubit>().selectPackage(package.id)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.nameAr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: ui.TextDirection.rtl,
                        ),
                        Text(
                          package.nameEn,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),

              // Download progress
              if (isDownloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: downloadProgress,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(downloadProgress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],

              // Content (if downloaded and selected)
              if (isDownloaded && isSelected && content != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  content!,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textDirection: package.language == 'ar'
                      ? ui.TextDirection.rtl
                      : ui.TextDirection.ltr,
                ),
              ],

              // Content not available message
              if (isDownloaded && isSelected && content == null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'quran.tafsir_not_available'.tr(),
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Download button
              if (!isDownloaded && !isDownloading) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.read<TafsirCubit>().downloadPackage(package.id),
                    icon: const Icon(Icons.download),
                    label: Text(
                      '${'quran.download'.tr()} (${package.sizeMb.toStringAsFixed(1)} MB)',
                    ),
                  ),
                ),
              ],

              // Delete button for downloaded packages
              if (isDownloaded && !isDownloading) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text('quran.delete_download'.tr()),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    if (isDownloading) {
      return Chip(
        label: Text('quran.downloading'.tr()),
        backgroundColor: Colors.blue.withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.blue, fontSize: 12),
      );
    }

    if (isDownloaded) {
      return Chip(
        label: Text('quran.downloaded'.tr()),
        backgroundColor: Colors.green.withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
      );
    }

    return Chip(
      label: Text('quran.not_downloaded'.tr()),
      backgroundColor: Colors.grey.withOpacity(0.1),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('quran.delete_download'.tr()),
        content: Text(
          '${'quran.delete_package_confirm'.tr()} "${package.nameEn}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<TafsirCubit>().deletePackage(package.id);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
