import 'package:flutter/material.dart';

class DateSelectorWidget extends StatelessWidget {
  final String dateText;
  final String subtitle;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const DateSelectorWidget({
    super.key,
    required this.dateText,
    required this.subtitle,
    this.onPrevious,
    this.onNext,
  });

  Widget _buildCircleIconButton(IconData icon, VoidCallback? onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: onPressed ?? () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircleIconButton(Icons.chevron_left, onPrevious),
        Column(
          children: [
            Text(
              dateText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],
        ),
        _buildCircleIconButton(Icons.chevron_right, onNext),
      ],
    );
  }
}