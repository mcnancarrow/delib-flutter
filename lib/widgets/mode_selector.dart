import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const ModeSelector({super.key, required this.selected, required this.onChanged});

  static const _modes = [
    _ModeOption('freethinkers', '🟣 Freethinkers', AppColors.ftA),
    _ModeOption('api',          '🔑 API Board',    AppColors.primary),
    _ModeOption('full',         '🌐 Full Board',   AppColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _modes.map((m) => _tab(m)).toList(),
      ),
    );
  }

  Widget _tab(_ModeOption m) {
    final active = selected == m.value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(m.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? m.color : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            m.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeOption {
  final String value;
  final String label;
  final Color color;
  const _ModeOption(this.value, this.label, this.color);
}
