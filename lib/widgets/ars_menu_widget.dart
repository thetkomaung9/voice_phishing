import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class ARSMenuWidget extends StatefulWidget {
  const ARSMenuWidget({super.key});

  @override
  State<ARSMenuWidget> createState() => _ARSMenuWidgetState();
}

class _ARSMenuWidgetState extends State<ARSMenuWidget> {
  int _step = 0;
  String? _selected;

  final _menus = [
    _ARSStep(
      title: 'KB국민은행 ARS',
      subtitle: 'Select a service',
      items: [
        _ARSItem(
          '1',
          '잔액조회',
          'Balance Inquiry',
          Icons.account_balance_wallet_rounded,
        ),
        _ARSItem('2', '이체', 'Transfer', Icons.swap_horiz_rounded),
        _ARSItem('3', '카드 서비스', 'Card Services', Icons.credit_card_rounded),
        _ARSItem(
          '4',
          '대출 상담',
          'Loan Consultation',
          Icons.request_quote_rounded,
        ),
        _ARSItem('0', '상담원 연결', 'Connect to Agent', Icons.headset_mic_rounded),
      ],
    ),
    _ARSStep(
      title: '잔액조회',
      subtitle: 'Select account type',
      items: [
        _ARSItem('1', '입출금 통장', 'Checking Account', Icons.savings_rounded),
        _ARSItem('2', '적금', 'Savings Account', Icons.trending_up_rounded),
        _ARSItem('9', '이전 메뉴', 'Previous Menu', Icons.arrow_back_rounded),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final menu = _menus[_step.clamp(0, _menus.length - 1)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.dialpad_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.title,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      menu.subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: menu.items.length,
              itemBuilder: (context, i) {
                final item = menu.items[i];
                return _ARSButton(
                  item: item,
                  selected: _selected == item.key,
                  onTap: () {
                    setState(() => _selected = item.key);
                    if (item.key == '1' && _step == 0) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        setState(() {
                          _step = 1;
                          _selected = null;
                        });
                      });
                    } else if (item.key == '9') {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        setState(() {
                          _step = 0;
                          _selected = null;
                        });
                      });
                    }
                  },
                ).animate().slideX(
                  begin: 0.1,
                  duration: 200.ms,
                  delay: (i * 50).ms,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ARSStep {
  final String title, subtitle;
  final List<_ARSItem> items;
  const _ARSStep({
    required this.title,
    required this.subtitle,
    required this.items,
  });
}

class _ARSItem {
  final String key, korean, english;
  final IconData icon;
  const _ARSItem(this.key, this.korean, this.english, this.icon);
}

class _ARSButton extends StatelessWidget {
  final _ARSItem item;
  final bool selected;
  final VoidCallback onTap;
  const _ARSButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withOpacity(0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  item.key,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              item.icon,
              color: selected ? AppColors.accent : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.korean,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    item.english,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
