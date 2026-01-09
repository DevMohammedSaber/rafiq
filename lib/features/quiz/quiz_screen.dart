import 'package:flutter/material.dart';
import '../../core/components/primary_button.dart';
import '../../core/theme/app_colors.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress
            Row(
              children: [
                Text(
                  "Question 1/5",
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                ),
                const Spacer(),
                const Icon(Icons.timer, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                const Text("00:45"),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.2,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.2),
              color: AppColors.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 32),

            // Question
            Text(
              "How many Surahs are there in the Holy Quran?",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Options
            Expanded(
              child: ListView(
                children: [
                  _buildOption(context, "110", false),
                  _buildOption(context, "114", true), // Selected mocking
                  _buildOption(context, "120", false),
                  _buildOption(context, "99", false),
                ],
              ),
            ),

            // Submit
            PrimaryButton(text: "Next Question", onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Theme.of(context).cardColor,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor.withOpacity(0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
