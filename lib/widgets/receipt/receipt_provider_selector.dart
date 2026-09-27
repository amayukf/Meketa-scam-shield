import 'package:flutter/material.dart';

class ReceiptProviderSelector extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final String selectedProvider;
  final ValueChanged<String> onSelected;

  const ReceiptProviderSelector({
    super.key,
    required this.providers,
    required this.selectedProvider,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: providers.map((p) {
          final isSelected = p['id'] == selectedProvider;
          final color = p['color'] as Color;
          final lightColor = p['lightColor'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              label: 'Select provider ${p['name']}',
              child: Tooltip(
                message: 'Select ${p['name']}',
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: lightColor,
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? color : color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  onSelected: (_) => onSelected(p['id'] as String),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
