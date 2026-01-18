import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq/features/quran/mushaf/data/mushaf_manifest_service.dart';
import 'package:rafiq/features/quran/mushaf/data/mushaf_zip_installer.dart';
import 'package:rafiq/features/quran/data/quran_user_data_repository.dart';
import 'package:rafiq/core/theme/app_colors.dart';

class MushafStorePage extends StatefulWidget {
  const MushafStorePage({super.key});

  @override
  State<MushafStorePage> createState() => _MushafStorePageState();
}

class _MushafStorePageState extends State<MushafStorePage> {
  final _manifestService = MushafManifestService(Dio());
  late final _installer = MushafZipInstaller(Dio());
  final _userDataRepo = QuranUserDataRepository();

  MushafManifest? manifest;
  bool isLoading = true;
  String? error;
  Map<String, bool> installedStatus = {};
  String? selectedMushafId;

  // Progress tracking
  String? installingId;
  double installProgress = 0.0;
  String installStatus = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        throw Exception("content.no_internet".tr());
      }

      manifest = await _manifestService.fetchManifest();
      await _refreshInstalledStatus();
      selectedMushafId = await _userDataRepo.getSelectedMushafId();
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshInstalledStatus() async {
    if (manifest == null) return;
    for (var m in manifest!.mushafs) {
      final isInstalled = await _installer.isMushafInstalled(m.id);
      installedStatus[m.id] = isInstalled;
    }
  }

  Future<void> _downloadMushaf(MushafInfo item) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("content.no_internet".tr())));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("quran.download_mushaf".tr()),
        content: Text("${item.nameEn}\n${"quran.downloading".tr()}..."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("common.confirm".tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      installingId = item.id;
      installProgress = 0.0;
      installStatus = "quran.downloading".tr();
    });

    try {
      final url = "${manifest!.baseUrl}/${item.zipPath}";

      await _installer.installMushaf(
        item.id,
        url,
        onProgress: (prog, status) {
          setState(() {
            installProgress = prog;
            installStatus = "quran.$status".tr();
          });
        },
      );

      await _refreshInstalledStatus();

      // Auto select if none selected
      if (selectedMushafId == null) {
        await _selectMushaf(item.id);
      }
    } catch (e) {
      final url = "${manifest!.baseUrl}/${item.zipPath}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed for $url\nError: $e"),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        installingId = null;
      });
    }
  }

  Future<void> _selectMushaf(String id) async {
    await _userDataRepo.setSelectedMushafId(id);
    setState(() {
      selectedMushafId = id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("quran.set_default_mushaf".tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteMushaf(MushafInfo item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("quran.delete_mushaf".tr()),
        content: Text("${item.nameEn}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("common.delete".tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _installer.deleteMushaf(item.id);

      // Clear selection if this was selected
      if (selectedMushafId == item.id) {
        await _userDataRepo.setSelectedMushafId('');
        selectedMushafId = null;
      }

      await _refreshInstalledStatus();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("quran.mushaf_store".tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(error!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: Text("common.retry".tr()),
                  ),
                ],
              ),
            );
          }

          if (manifest == null) return const Center(child: Text("No data"));

          // Separate installed and available mushafs
          final installedMushafs = manifest!.mushafs
              .where((m) => installedStatus[m.id] == true)
              .toList();
          final availableMushafs = manifest!.mushafs
              .where((m) => installedStatus[m.id] != true)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Installed Mushafs Section (My Mushafs)
              if (installedMushafs.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.menu_book,
                  title: "quran.my_mushafs".tr(),
                  subtitle: "quran.my_mushafs_desc".tr(),
                ),
                const SizedBox(height: 12),
                ...installedMushafs.map(
                  (item) => _InstalledMushafCard(
                    item: item,
                    isSelected: selectedMushafId == item.id,
                    onSelect: () => _selectMushaf(item.id),
                    onOpen: () {
                      _selectMushaf(item.id).then((_) {
                        Navigator.pop(context, true);
                      });
                    },
                    onDelete: () => _deleteMushaf(item),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Available Mushafs Section (Store)
              if (availableMushafs.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.store,
                  title: "quran.available_mushafs".tr(),
                  subtitle: "quran.available_mushafs_desc".tr(),
                ),
                const SizedBox(height: 12),
                ...availableMushafs.map((item) {
                  final isInstalling = installingId == item.id;
                  return _AvailableMushafCard(
                    item: item,
                    isInstalling: isInstalling,
                    installProgress: installProgress,
                    installStatus: installStatus,
                    onDownload: () => _downloadMushaf(item),
                  );
                }),
              ],

              // Empty state if no mushafs available
              if (installedMushafs.isEmpty && availableMushafs.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("quran.no_packages".tr()),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstalledMushafCard extends StatelessWidget {
  final MushafInfo item;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _InstalledMushafCard({
    required this.item,
    required this.isSelected,
    required this.onSelect,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Mushaf Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nameAr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.nameEn,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "quran.default".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isSelected)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSelect,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text("quran.set_default".tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (!isSelected) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text("quran.open_mushaf".tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  tooltip: "common.delete".tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableMushafCard extends StatelessWidget {
  final MushafInfo item;
  final bool isInstalling;
  final double installProgress;
  final String installStatus;
  final VoidCallback onDownload;

  const _AvailableMushafCard({
    required this.item,
    required this.isInstalling,
    required this.installProgress,
    required this.installStatus,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Mushaf Icon (dimmed for not installed)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nameAr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.nameEn,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Page count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${item.pageCount} ${"quran.pages".tr()}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isInstalling) ...[
              LinearProgressIndicator(
                value: installProgress,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    installStatus,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    "${(installProgress * 100).toInt()}%",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 18),
                  label: Text("quran.download_mushaf".tr()),
                  onPressed: onDownload,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
