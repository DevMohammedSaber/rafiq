import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../cubit/azkar_categories_cubit.dart';
import '../../domain/models/azkar_category.dart';
import '../../../../core/theme/app_colors.dart';

class AzkarCategoriesPage extends StatefulWidget {
  const AzkarCategoriesPage({super.key});

  @override
  State<AzkarCategoriesPage> createState() => _AzkarCategoriesPageState();
}

class _AzkarCategoriesPageState extends State<AzkarCategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AzkarCategoriesCubit>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("azkar.title".tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/azkar/reminders');
            },
          ),
        ],
      ),
      body: BlocBuilder<AzkarCategoriesCubit, AzkarCategoriesState>(
        builder: (context, state) {
          if (state is AzkarCategoriesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AzkarCategoriesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AzkarCategoriesCubit>().loadCategories();
                    },
                    child: Text("common.retry".tr()),
                  ),
                ],
              ),
            );
          }

          if (state is AzkarCategoriesLoaded) {
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return _CategoryCard(category: category);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AZkarCategory category;

  const _CategoryCard({required this.category});

  IconData _getIcon(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.nights_stay_rounded;
      case 'sleep':
        return FontAwesomeIcons.bed;
      case 'after_prayer':
        return FontAwesomeIcons.handsPraying;
      case 'hisn_almuslim':
        return FontAwesomeIcons.shieldHalved;
      default:
        return Icons.bookmark;
    }
  }

  Color _getColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return Colors.orange;
      case 'evening':
        return Colors.indigo;
      case 'sleep':
        return Colors.purple;
      case 'after_prayer':
        return AppColors.primary;
      case 'hisn_almuslim':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/azkar/category/${category.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColor(category.id).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(category.id),
                color: _getColor(category.id),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRTL ? category.nameAr : category.nameEn,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
