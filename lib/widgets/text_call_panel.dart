import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class TextCallPanel extends StatefulWidget {
  const TextCallPanel({super.key});

  @override
  State<TextCallPanel> createState() => _TextCallPanelState();
}

class _TextCallPanelState extends State<TextCallPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final messages = provider.textCallMessages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Text Call',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Type a message and Safe-Call reads it out loud.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message.speaker == TextCallSpeaker.user;
                  final bubbleColor = _bubbleColor(message.speaker);
                  final borderColor = isUser
                      ? AppColors.primary.withValues(alpha: 0.8)
                      : Colors.white10;

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _speakerLabel(message.speaker),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          if (message.myanmarText.isNotEmpty ||
                              message.englishText.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            if (message.myanmarText.isNotEmpty)
                              _TranslatedTextLine(
                                label: 'Myanmar',
                                text: message.myanmarText,
                              ),
                            if (message.englishText.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: message.myanmarText.isNotEmpty ? 8 : 0,
                                ),
                                child: _TranslatedTextLine(
                                  label: 'English',
                                  text: message.englishText,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (provider.quickTextCallReplies.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final reply = provider.quickTextCallReplies[index];
                    return ActionChip(
                      backgroundColor: const Color(0xFF202938),
                      side: const BorderSide(color: Colors.white12),
                      label: Text(
                        reply,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => _sendMessage(provider, reply),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemCount: provider.quickTextCallReplies.length,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a reply for the caller',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendCurrentMessage(provider),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendCurrentMessage(provider),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
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

  void _sendCurrentMessage(AppProvider provider) {
    _sendMessage(provider, _controller.text);
  }

  void _sendMessage(AppProvider provider, String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    provider.sendTextCallMessage(trimmed);
    _controller.clear();
  }

  String _speakerLabel(TextCallSpeaker speaker) {
    switch (speaker) {
      case TextCallSpeaker.assistant:
        return 'Safe-Call';
      case TextCallSpeaker.caller:
        return 'Caller';
      case TextCallSpeaker.user:
        return 'You';
    }
  }

  Color _bubbleColor(TextCallSpeaker speaker) {
    switch (speaker) {
      case TextCallSpeaker.user:
        return AppColors.primary;
      case TextCallSpeaker.assistant:
        return const Color(0xFF202938);
      case TextCallSpeaker.caller:
        return AppColors.card;
    }
  }
}

class _TranslatedTextLine extends StatelessWidget {
  final String label;
  final String text;

  const _TranslatedTextLine({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
