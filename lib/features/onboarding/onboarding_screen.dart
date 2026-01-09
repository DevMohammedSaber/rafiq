import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/primary_button.dart';
import '../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _items = [
    {
      'image': 'assets/images/onboarding_1.svg', // Placeholder
      'titleKey': 'onboarding.title1',
      'descKey': 'onboarding.desc1',
    },
    {
      'image': 'assets/images/onboarding_2.svg',
      'titleKey': 'onboarding.title2',
      'descKey': 'onboarding.desc2',
    },
    {
      'image': 'assets/images/onboarding_3.svg',
      'titleKey': 'onboarding.title3',
      'descKey': 'onboarding.desc3',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header: Language Toggle
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      final newLocale = context.locale.languageCode == 'en'
                          ? const Locale('ar')
                          : const Locale('en');
                      context.setLocale(newLocale);
                    },
                    child: Text(
                      context.locale.languageCode == 'ar'
                          ? 'English'
                          : 'العربية',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Placeholder for image
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.image,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _items[index]['titleKey']!.tr(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _items[index]['descKey']!.tr(),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer: Indicator & Button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _items.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: Colors.grey,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: _currentPage == _items.length - 1
                        ? "onboarding.get_started".tr()
                        : "onboarding.continue".tr(),
                    onPressed: () {
                      if (_currentPage < _items.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/location');
                      }
                    },
                  ),
                  if (_currentPage < _items.length - 1)
                    TextButton(
                      onPressed: () => context.go('/location'),
                      child: Text(
                        "onboarding.skip".tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
