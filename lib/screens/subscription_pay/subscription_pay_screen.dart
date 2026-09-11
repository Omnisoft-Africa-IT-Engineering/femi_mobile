import 'package:flutter/material.dart';
import 'widgets/payment_option_card_widget.dart';
import 'widgets/plan_detail_card_widget.dart';
import 'widgets/plan_tab_widget.dart';
import '../../states/auth_state.dart';
import 'widgets/target_feature_banner_widget.dart';

// NOTE : FemiApiService n'est plus appelé pour l'instant (voir _gererPaiement).
// Import conservé pour faciliter la réactivation future du paiement réel.
import '../../services/femi_api_service.dart';

class SubscriptionPayScreen extends StatefulWidget {
  final String? targetFeature;

  const SubscriptionPayScreen({super.key, this.targetFeature});

  @override
  State<SubscriptionPayScreen> createState() => _SubscriptionPayScreenState();
}

class _SubscriptionPayScreenState extends State<SubscriptionPayScreen> {
  int _selectedPlanIndex = 1; // 0: Micro, 1: Pro, 2: Business
  int _selectedPaymentMethod = 0; // 0: Mobile Money, 1: Carte bancaire
  bool _isLoading = false;

  // Instance conservée pour réactivation future de l'appel API réel.
  // ignore: unused_field
  final FemiApiService _apiService = FemiApiService();

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

  // MODE TEST : déblocage instantané sans appel serveur.
  // TODO: remettre l'appel réel à _apiService.activatePlan(...) avant la mise en prod,
  // et faire dépendre AuthState.instance.isPro.value de la réponse réelle du backend.
  Future<void> _gererPaiement(Map<String, dynamic> selectedPlan) async {
    setState(() => _isLoading = true);

    debugPrint('⚠️ MODE TEST : paiement désactivé, activation instantanée.');

    // Petit délai pour garder le spinner visible un instant (UX).
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Déblocage global immédiat : c'est CETTE ligne qui débloque réellement
    // les fonctionnalités PRO partout dans l'app (CompteScreen inclus),
    // car isPro est un état global écouté, pas une variable locale.
    AuthState.instance.isPro.value = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Formule ${selectedPlan['title']} activée avec succès !'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // On repop simplement vers l'écran précédent (ex: CompteScreen),
    // au lieu de vider toute la pile de navigation : plus besoin de
    // renvoyer un résultat via Navigator.pop(true), l'état global suffit.
    Navigator.of(context).pop(true);

    setState(() => _isLoading = false);
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

                    // 3. Méthodes de paiement (visuelles)
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
                  onPressed: _isLoading
                      ? null
                      : () => _gererPaiement(selectedPlan),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Activer la formule ${selectedPlan['title']} (${selectedPlan['price']})',
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