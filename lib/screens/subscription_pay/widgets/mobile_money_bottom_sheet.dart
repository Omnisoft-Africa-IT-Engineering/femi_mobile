import 'package:flutter/material.dart';

// 1. BOTTOM SHEET POUR LA SAISIE DU NUMÉRO MOBILE MONEY
class MobileMoneyBottomSheet extends StatefulWidget {
  final String initialPhoneNumber;
  final double amount;
  final String currency;
  final Function(String phoneNumber, String provider) onConfirmPayment;

  const MobileMoneyBottomSheet({
    super.key,
    required this.initialPhoneNumber,
    required this.amount,
    this.currency = 'FCFA',
    required this.onConfirmPayment,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialPhoneNumber,
    required double amount,
    String currency = 'FCFA',
    required Function(String phoneNumber, String provider) onConfirmPayment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MobileMoneyBottomSheet(
        initialPhoneNumber: initialPhoneNumber,
        amount: amount,
        currency: currency,
        onConfirmPayment: onConfirmPayment,
      ),
    );
  }

  @override
  State<MobileMoneyBottomSheet> createState() => _MobileMoneyBottomSheetState();
}

class _MobileMoneyBottomSheetState extends State<MobileMoneyBottomSheet> {
  late TextEditingController _phoneController;
  String _selectedProvider = 'T-Money';

  final List<Map<String, String>> _providers = [
    {'name': 'T-Money', 'icon': '📲'},
    {'name': 'Flooz', 'icon': '💳'},
    {'name': 'Wave', 'icon': '🌊'},
    {'name': 'MTN MoMo', 'icon': '💛'},
  ];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Paiement Mobile Money',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Montant à débiter : ${widget.amount.toStringAsFixed(0)} ${widget.currency}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sélectionnez l\'opérateur',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _providers.map((provider) {
                  final isSelected = _selectedProvider == provider['name'];
                  return ChoiceChip(
                    avatar: Text(provider['icon']!),
                    label: Text(provider['name']!),
                    selected: isSelected,
                    selectedColor: const Color(0xFFEFF6FF),
                    backgroundColor: const Color(0xFFF8FAFC),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _selectedProvider = provider['name']!);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Numéro de téléphone à débiter',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Ex: +228 90 00 00 00',
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final phone = _phoneController.text.trim();
                    if (phone.isEmpty) return;
                    Navigator.pop(context);
                    widget.onConfirmPayment(phone, _selectedProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Envoyer la demande USSD',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. DIALOGUE D'ATTENTE DE VALIDATION DU CODE PIN
class USSDWaitingDialog {
  static Future<void> show(
    BuildContext context, {
    required String phoneNumber,
    required String provider,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Validation en cours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Text(
              'Une notification $provider a été envoyée au $phoneNumber.\n\nVeuillez valider le paiement avec votre code PIN secret sur votre téléphone.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_clock, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text(
                    'En attente du PIN...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}