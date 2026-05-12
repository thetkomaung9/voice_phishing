import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TranslationBubble extends StatelessWidget {
  final String text;
  final String englishText;
  final String myanmarText;

  const TranslationBubble({
    super.key,
    required this.text,
    this.englishText = '',
    this.myanmarText = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.translate_rounded,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Translation',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (myanmarText.trim().isNotEmpty)
            _TranslationLine(label: 'Myanmar', text: myanmarText),
          if (englishText.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: myanmarText.trim().isNotEmpty ? 10 : 0,
              ),
              child: _TranslationLine(label: 'English', text: englishText),
            ),
          if (myanmarText.trim().isEmpty && englishText.trim().isEmpty)
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }
}

class _TranslationLine extends StatelessWidget {
  final String label;
  final String text;

  const _TranslationLine({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
