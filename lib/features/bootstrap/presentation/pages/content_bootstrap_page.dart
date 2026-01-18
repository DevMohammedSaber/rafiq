import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/content_bootstrap_cubit.dart';

/// Bootstrap page that shows content download/import progress.
/// Displayed on first launch or when content needs updating.
class ContentBootstrapPage extends StatefulWidget {
  const ContentBootstrapPage({super.key});

  @override
  State<ContentBootstrapPage> createState() => _ContentBootstrapPageState();
}

class _ContentBootstrapPageState extends State<ContentBootstrapPage> {
  @override
  void initState() {
    super.initState();
    // Start bootstrap process
    context.read<ContentBootstrapCubit>().startBootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<ContentBootstrapCubit, ContentBootstrapState>(
            listener: (context, state) {
              if (state is ContentBootstrapComplete) {
                // Navigate to home
                context.go('/home');
              }
            },
            builder: (context, state) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // App name
                      Text(
                        'app.name'.tr(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Progress content
                      _buildProgressContent(state),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressContent(ContentBootstrapState state) {
    if (state is ContentBootstrapError) {
      return _buildErrorContent(state);
    }

    final message = state is ContentBootstrapLoading
        ? state.message
        : 'bootstrap.preparing'.tr();
    final progress = state is ContentBootstrapLoading ? state.progress : 0.0;

    return Column(
      children: [
        // Loading indicator
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 24),

        // Status message
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),

        if (progress > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorContent(ContentBootstrapError state) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        const SizedBox(height: 16),
        Text(
          'bootstrap.error'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            context.read<ContentBootstrapCubit>().retry();
          },
          icon: const Icon(Icons.refresh),
          label: Text('common.retry'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      ],
    );
  }
}
