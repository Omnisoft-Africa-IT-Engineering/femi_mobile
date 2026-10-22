import 'package:flutter/material.dart';

const Color _vert = Color(0xFF0D5C52);
const Color _vertClair = Color(0xFFEAF6F3);

String _fcfa(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf FCFA';
}

class PlanDetailCardWidget extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PlanDetailCardWidget({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final title = (plan['title'] as String?) ?? '';
    final priceEuro = (plan['price'] as String?) ?? '';
    final amountFcfa = (plan['amountFcfa'] as num?) ?? 0;
    final period = (plan['period'] as String?) ?? '';
    final description = (plan['description'] as String?) ?? '';
    final features = (plan['features'] as List<String>?) ?? [];
    final isPopular = (plan['isPopular'] as bool?) ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? _vert : Colors.grey.shade200,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _vertClair,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LE PLUS CHOISI',
                    style: TextStyle(
                      color: _vert,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 16),
          // Prix principal : FCFA
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fcfa(amountFcfa),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                period,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          // Prix secondaire : euro
          if (priceEuro.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '≈ $priceEuro $period',
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
          const Divider(height: 32),

          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: _vert,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}