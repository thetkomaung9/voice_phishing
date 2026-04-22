import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'Language'),
          ...Language.values.map((lang) {
            final labels = {
              Language.burmese: ('🇲🇲', 'မြန်မာဘာသာ'),
              Language.vietnamese: ('🇻🇳', 'Tiếng Việt'),
              Language.chinese: ('🇨🇳', '中文'),
              Language.english: ('🇬🇧', 'English'),
            };
            final (flag, name) = labels[lang]!;
            return _SettingsTile(
              leading: Text(flag, style: const TextStyle(fontSize: 24)),
              title: name,
              trailing: provider.selectedLanguage == lang
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () => provider.setLanguage(lang),
            );
          }),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Protection'),
          _SettingsTile(
            leading: const Icon(Icons.shield_rounded, color: AppColors.primary),
            title: 'Real-time Protection',
            subtitle: 'Monitor calls for phishing',
            trailing: Switch(
              value: provider.protectionEnabled,
              onChanged: (_) => provider.toggleProtection(),
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'About'),
          _SettingsTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
            ),
            title: 'Safe-Call AI',
            subtitle: 'Version 1.0.0 MVP',
          ),
          _SettingsTile(
            leading: const Icon(
              Icons.security_rounded,
              color: AppColors.textSecondary,
            ),
            title: 'Privacy Policy',
            subtitle: 'Zero-Retention data policy',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
