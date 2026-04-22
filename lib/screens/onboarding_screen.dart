import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  Language? _selectedLang;

  final _pages = [
    _OnboardPage(
      icon: Icons.shield_rounded,
      color: AppColors.primary,
      title: 'Safe-Call AI',
      subtitle: 'Real-time call protection\nfor foreigners in Korea',
    ),
    _OnboardPage(
      icon: Icons.translate_rounded,
      color: AppColors.accent,
      title: 'Live Translation',
      subtitle: 'Korean calls translated\nto your language instantly',
    ),
    _OnboardPage(
      icon: Icons.warning_amber_rounded,
      color: AppColors.danger,
      title: 'Phishing Shield',
      subtitle: 'AI detects voice phishing\nand alerts you in real-time',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _page < 3 ? _buildSlide() : _buildLanguagePicker()),
    );
  }

  Widget _buildSlide() {
    final p = _pages[_page];
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: p.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(p.icon, size: 60, color: p.color),
          ).animate().scale(duration: 400.ms),
          const SizedBox(height: 40),
          Text(
            p.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white60, height: 1.6),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _page++),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _page == 2 ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker() {
    final langs = [
      (Language.burmese, '🇲🇲', 'မြန်မာဘာသာ', 'Burmese'),
      (Language.vietnamese, '🇻🇳', 'Tiếng Việt', 'Vietnamese'),
      (Language.chinese, '🇨🇳', '中文', 'Chinese'),
      (Language.english, '🇬🇧', 'English', 'English'),
    ];
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Select Your Language',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your native language for translations',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ...langs.map(
            (l) => _LangTile(
              flag: l.$2,
              native: l.$3,
              english: l.$4,
              selected: _selectedLang == l.$1,
              onTap: () => setState(() => _selectedLang = l.$1),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedLang == null
                  ? null
                  : () {
                      context.read<AppProvider>().setLanguage(_selectedLang!);
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Start Protection',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _LangTile extends StatelessWidget {
  final String flag, native, english;
  final bool selected;
  final VoidCallback onTap;
  const _LangTile({
    required this.flag,
    required this.native,
    required this.english,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  native,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  english,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
