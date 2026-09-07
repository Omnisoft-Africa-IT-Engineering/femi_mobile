import 'package:flutter/material.dart';
import 'widgets/payment_option_card_widget.dart';
import 'widgets/plan_detail_card_widget.dart';
import 'widgets/plan_tab_widget.dart';
import 'widgets/mobile_money_bottom_sheet.dart';
import '../../states/auth_state.dart';
import 'widgets/target_feature_banner_widget.dart';

class SubscriptionPayScreen extends StatefulWidget {
  final String? targetFeature;

  const SubscriptionPayScreen({super.key, this.targetFeature});

  @override
  State<SubscriptionPayScreen> createState() => _SubscriptionPayScreenState();
}

class _SubscriptionPayScreenState extends State<SubscriptionPayScreen> {
  int _selectedPlanIndex = 1; // 0: Micro, 1: Pro, 2: Business
  int _selectedPaymentMethod = 0; // 0: Mobile Money, 1: Carte bancaire

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Micro',
      'price': '10.99€',
      'amountFcfa': 7200.0,
      'period': '/ mois',
      'description':
          'Idéal pour démarrer et gérer les flux quotidiens de votre activité.',
      'features': [
        'Registre journalier de caisse',
        'Saisie illimitée des transactions',
        'Support standard par email',
        'Historique conservé sur 6 mois',
      ],
      'isPopular': false,
    },
    {
      'title': 'Pro',
      'price': '20.99€',
      'amountFcfa': 13750.0,
      'period': '/ mois',
      'description':
          'Pour piloter votre PME comme si vous aviez un comptable à temps plein.',
      'features': [
        'Tout ce qui est inclus dans Micro',
        'Alertes en temps réel sur vos produits les plus performants',
        'Documents comptables : État, Balance, Grand Livre',
        'Support prioritaire',
        'Historique conservé d\'une année sur l\'autre',
      ],
      'isPopular': true,
    },
    {
      'title': 'Business',
      'price': '30.99€',
      'amountFcfa': 20300.0,
      'period': '/ mois',
      'description':
          'Pour les structures multi-établissements avec accompagnement dédié.',
      'features': [
        'Tout ce qui est inclus dans Pro',
        'Accompagnement mensuel par un consultant Femi',
        'Exportation personnalisée des rapports',
        'Gestion multi-utilisateurs',
      ],
      'isPopular': false,
    },
  ];

  // Gestion du paiement
  // Gestion de la simulation de paiement
  void _gererPaiement(Map<String, dynamic> selectedPlan) {
    if (_selectedPaymentMethod == 0) {
      // 1. MOBILE MONEY : Ouvrir le BottomSheet
      MobileMoneyBottomSheet.show(
        context: context,
        initialPhoneNumber: '+22890000000', // Numéro par défaut
        amount: selectedPlan['amountFcfa'] ?? 13750.0,
        currency: 'FCFA',
        onConfirmPayment: (phone, provider) async {
          // 2. Afficher la boîte de dialogue d'attente / simulation PIN
          USSDWaitingDialog.show(
            context,
            phoneNumber: phone,
            provider: provider,
          );

          // 3. Simuler une attente de validation USSD de 2 secondes
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            // 4. Fermer la boîte de dialogue USSD
            Navigator.pop(context);

            // 5. Mettre à jour l'état d'authentification pour connecter l'utilisateur
            AuthState.instance.isLoggedIn.value = true;

            // 6. Rediriger directement vers le Dashboard (en nettoyant tout l'historique de navigation)
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/', // Redirige vers AuthGate qui basculera vers le Dashboard/MainNavigationScreen
              (route) => false,
            );
          }
        },
      );
    } else {
      // 2. CARTE BANCAIRE (Simulation directe)
      AuthState.instance.isLoggedIn.value = true;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlan = _plans[_selectedPlanIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Nos Formules d\'Abonnement',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avertissement si verrouillage d'une fonctionnalité
                    if (widget.targetFeature != null)
                      TargetFeatureBannerWidget(
                        targetFeature: widget.targetFeature!,
                      ),

                    // 1. Sélecteur de Formule en Onglets
                    Row(
                      children: List.generate(_plans.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index < _plans.length - 1 ? 8.0 : 0.0,
                            ),
                            child: PlanTabWidget(
                              plan: _plans[index],
                              isSelected: _selectedPlanIndex == index,
                              onTap: () =>
                                  setState(() => _selectedPlanIndex = index),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // 2. Carte Détail du Plan Sélectionné
                    PlanDetailCardWidget(plan: selectedPlan),
                    const SizedBox(height: 24),

                    // 3. Méthodes de paiement
                    const Text(
                      'Méthode de paiement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    PaymentOptionCardWidget(
                      index: 0,
                      groupValue: _selectedPaymentMethod,
                      icon: Icons.phone_android,
                      title: 'Mobile Money',
                      subtitle: 'Flooz, T-Money, Wave, MoMo',
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPaymentMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    PaymentOptionCardWidget(
                      index: 1,
                      groupValue: _selectedPaymentMethod,
                      icon: Icons.credit_card,
                      title: 'Carte Bancaire',
                      subtitle: 'Visa, Mastercard',
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPaymentMethod = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bouton d'action fixe en bas
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _gererPaiement(selectedPlan),
                  child: Text(
                    'Payer ${selectedPlan['price']} / mois',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}