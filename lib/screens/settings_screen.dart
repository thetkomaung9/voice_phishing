import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/native_channel_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NativeChannelService _native = NativeChannelService();
  bool _overlayEnabled = false;
  bool _callScreeningEnabled = false;
  bool _textCallCaptureEnabled = false;

  @override
  void initState() {
    super.initState();
    _refreshIntegrationStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIntegrationStatus();
  }

  Future<void> _refreshIntegrationStatus() async {
    try {
      final overlayEnabled = await _native.hasOverlayPermission();
      final callScreeningEnabled = await _native.isCallScreeningEnabled();
      final textCallCaptureEnabled = await _native
          .isSamsungTextCallCaptureEnabled();
      if (!mounted) return;
      setState(() {
        _overlayEnabled = overlayEnabled;
        _callScreeningEnabled = callScreeningEnabled;
        _textCallCaptureEnabled = textCallCaptureEnabled;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _overlayEnabled = false;
        _callScreeningEnabled = false;
        _textCallCaptureEnabled = false;
      });
    }
  }

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
          _SectionHeader(title: 'Phone Integration'),
          _SettingsTile(
            leading: const Icon(
              Icons.phone_in_talk_rounded,
              color: AppColors.primary,
            ),
            title: 'Use Original Phone UI',
            subtitle:
                'Keep Samsung/Android call screen and add Safe-Call overlay',
            trailing: _StatusPill(
              label: _callScreeningEnabled ? 'Enabled' : 'Setup',
              active: _callScreeningEnabled,
            ),
            onTap: () async {
              await _native.openCallScreeningSettings();
              await _refreshIntegrationStatus();
            },
          ),
          _SettingsTile(
            leading: const Icon(Icons.layers_rounded, color: AppColors.accent),
            title: 'Overlay Permission',
            subtitle:
                'Allow translation and phishing warnings over incoming calls',
            trailing: _StatusPill(
              label: _overlayEnabled ? 'Allowed' : 'Grant',
              active: _overlayEnabled,
            ),
            onTap: () async {
              await _native.requestOverlayPermission();
              await _refreshIntegrationStatus();
            },
          ),
          _SettingsTile(
            leading: const Icon(
              Icons.mic_rounded,
              color: AppColors.textSecondary,
            ),
            title: 'Microphone Permission',
            subtitle: 'Needed for live transcription during calls',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
            ),
            onTap: () async {
              await Permission.microphone.request();
              await _refreshIntegrationStatus();
            },
          ),
          _SettingsTile(
            leading: const Icon(
              Icons.text_fields_rounded,
              color: AppColors.warning,
            ),
            title: 'Samsung Text Call Capture',
            subtitle:
                'Read visible Samsung Text Call text for scam detection and translation',
            trailing: _StatusPill(
              label: _textCallCaptureEnabled ? 'Enabled' : 'Setup',
              active: _textCallCaptureEnabled,
            ),
            onTap: () async {
              await _native.openAccessibilitySettings();
              await _refreshIntegrationStatus();
            },
          ),
          const SizedBox(height: 24),
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

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.accent.withValues(alpha: 0.18)
            : Colors.white12,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppColors.accent.withValues(alpha: 0.35)
              : Colors.white24,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.accent : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
