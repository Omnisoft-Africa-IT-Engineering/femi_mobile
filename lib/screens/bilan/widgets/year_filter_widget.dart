import 'package:flutter/material.dart';

class YearFilterWidget extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int> onYearSelected;

  const YearFilterWidget({
    super.key,
    required this.selectedYear,
    required this.onYearSelected,
  });

  @override
  Widget build(BuildContext context) {
    final years = [2023, 2022, 2021];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF1FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ...years.map((year) {
            final isSelected = year == selectedYear;
            return Expanded(
              child: GestureDetector(
                onTap: () => onYearSelected(year),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const CircleAvatar(radius: 2, backgroundColor: Colors.green),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.tune, size: 18, color: Colors.grey),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}