import 'package:flutter/material.dart';
import 'widgets/payment_option_card_widget.dart';
import 'widgets/plan_detail_card_widget.dart';
import 'widgets/plan_tab_widget.dart';
import '../../states/auth_state.dart';
import 'widgets/target_feature_banner_widget.dart';
import '../../services/fedapay_service.dart';
import '../../services/femi_api_service.dart';
import 'payment_webview_screen.dart';

class SubscriptionPayScreen extends StatefulWidget {
  final String? targetFeature;

  final String? nomComplet;
  final String? email;
  final String? password;
  final String? nomEntreprise;
  final String? secteurNom;
  final String? telephoneWhatsapp;
  final String? devise;
  final String? typeEntreprise;

  const SubscriptionPayScreen({
    super.key,
    this.targetFeature,
    this.nomComplet,
    this.email,
    this.password,
    this.nomEntreprise,
    this.secteurNom,
    this.telephoneWhatsapp,
    this.devise,
    this.typeEntreprise,
  });

  /// true si l'écran est ouvert depuis l'onboarding
  bool get isOnboarding =>
      email != null && nomEntreprise != null;

  @override
  State<SubscriptionPayScreen> createState() =>
      _SubscriptionPayScreenState();
}

class _SubscriptionPayScreenState extends State<SubscriptionPayScreen> {
  int _selectedPlanIndex = 1;
  int _selectedPaymentMethod = 0;
  bool _isLoading = false;

  bool _paiementEnAttenteDeCompte = false;
  Map<String, dynamic>? _donneesEnAttente;

  final FedaPayService _fedaPayService = FedaPayService();
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

  /// Tente de créer le compte jusqu'à 3 fois.
  Future<bool> _creerCompteAvecRetries(
      Map<String, dynamic> donnees) async {
    const maxTentatives = 3;
    final identifiant = donnees['email'] as String;
    final motDePasse = donnees['password'] as String;

    for (var tentative = 1;
        tentative <= maxTentatives;
        tentative++) {
      final success = await AuthState.instance.register(
        username: identifiant,
        password: motDePasse,
        nomEntreprise: donnees['nomEntreprise'] as String,
        nomComplet: donnees['nomComplet'] as String?,
        email: identifiant,
        telephoneWhatsapp:
            donnees['telephoneWhatsapp'] as String?,
        secteurNom: donnees['secteurNom'] as String?,
        devise: donnees['devise'] as String?,
        typeEntreprise: donnees['typeEntreprise'] as String?,
      );

      if (success) return true;

      final dejaCree = await AuthState.instance.login(
        identifiant,
        motDePasse,
      );

      if (dejaCree) {
        AuthState.instance.errorMessage.value = null;
        return true;
      }

      if (tentative < maxTentatives) {
        await Future.delayed(
          Duration(seconds: 2 * tentative),
        );
      }
    }

    return false;
  }

  /// Met à jour la sauvegarde locale.
  Future<void> _finaliserSauvegarde(
    Map<String, dynamic> donnees, {
    required bool formuleActivee,
  }) async {
    if (formuleActivee) {
      await _apiService.clearPendingRegistration();
      return;
    }

    await _apiService.savePendingRegistration({
      'compteCree': true,
      'email': donnees['email'],
      'planTitle': donnees['planTitle'],
      'transactionId': donnees['transactionId'],
    });
  }

  /// Réessai manuel après paiement confirmé.
  Future<void> _reessayerCreationCompte() async {
    final donnees = _donneesEnAttente;

    if (donnees == null) return;

    setState(() => _isLoading = true);

    final success = await _creerCompteAvecRetries(donnees);

    if (!mounted) return;

    if (success) {
      final planTitle = donnees['planTitle'] as String;
      final transactionId =
          donnees['transactionId'] as String?;

      final formuleActivee =
          await _activerFormuleCoteServeur(
        planTitle: planTitle,
        transactionId: transactionId,
      );

      if (!mounted) return;

      await _finaliserSauvegarde(
        donnees,
        formuleActivee: formuleActivee,
      );

      setState(() {
        _isLoading = false;
        _paiementEnAttenteDeCompte = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte créé avec succès ! Bienvenue sur Femi 🎉',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } else {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Toujours impossible de créer le compte. '
            'Réessayez plus tard ou contactez le support '
            'avec la référence de transaction.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Active la formule après paiement confirmé.
  Future<bool> _activerFormuleCoteServeur({
    required String planTitle,
    String? transactionId,
  }) async {
    final activated = await _apiService.activatePlan(
      planTitle: planTitle,
      transactionId: transactionId,
    );

    if (activated) {
      await AuthState.instance.refreshIsProFromBackend();
      return true;
    }

    debugPrint(
      '⚠️ activatePlan a échoué côté serveur alors que FedaPay '
      'a confirmé le paiement (transaction_id: $transactionId).',
    );

    AuthState.instance.isPro.value = true;

    return false;
  }

  // ============================================================
  // NOUVEAU : PASSER L'ABONNEMENT
  // ============================================================

  Future<void> _passerAbonnement() async {
    // Sécurité : le bouton ne doit fonctionner
    // que pendant l'onboarding.
    if (!widget.isOnboarding) return;

    setState(() => _isLoading = true);

    final donnees = <String, dynamic>{
      'email': widget.email,
      'password': widget.password,
      'nomEntreprise': widget.nomEntreprise,
      'nomComplet': widget.nomComplet,
      'telephoneWhatsapp': widget.telephoneWhatsapp,
      'secteurNom': widget.secteurNom,
      'devise': widget.devise ?? 'FCFA',
      'typeEntreprise': widget.typeEntreprise,
    };

    // Sauvegarde de sécurité avant la création du compte.
    await _apiService.savePendingRegistration(donnees);

    final success =
        await _creerCompteAvecRetries(donnees);

    if (!mounted) return;

    if (success) {
      // Aucun abonnement n'est activé ici.
      // L'utilisateur a simplement choisi de passer.
      await _apiService.clearPendingRegistration();

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte créé avec succès ! Bienvenue sur Femi 🎉',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // AuthGate affichera automatiquement
      // l'application principale puisque l'utilisateur
      // est maintenant connecté.
      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } else {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de créer le compte. '
            'Vérifiez votre connexion et réessayez.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _gererPaiement(
      Map<String, dynamic> selectedPlan) async {
    setState(() => _isLoading = true);

    String firstname;
    String lastname;
    String phone;
    String email;

    if (widget.isOnboarding) {
      final parts =
          widget.nomComplet!.trim().split(RegExp(r'\s+'));

      firstname =
          parts.isNotEmpty ? parts.first : widget.nomComplet!;

      lastname =
          parts.length > 1
              ? parts.sublist(1).join(' ')
              : '';

      phone = widget.telephoneWhatsapp ?? '';
      email = widget.email!;
    } else {
      firstname = '';
      lastname = '';
      phone = '';
      email = '';
    }

    final montant =
        (selectedPlan['amountFcfa'] as double).round();

    final result =
        await _fedaPayService.creerPaiement(
      description:
          'Abonnement Femi - ${selectedPlan['title']}',
      amount: montant,
      firstname: firstname,
      lastname: lastname,
      phone: phone,
      email: email,
    );

    if (!mounted) return;

    if (!result.success ||
        result.paymentUrl == null) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                "Impossible d'initier le paiement.",
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final paiementReussi =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentWebViewScreen(
          paymentUrl: result.paymentUrl!,
          callbackUrlPrefix:
              FedaPayService.callbackUrlPrefix,
        ),
      ),
    );

    if (!mounted) return;

    if (paiementReussi != true) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paiement annulé ou échoué.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    // Paiement confirmé.
    if (widget.isOnboarding) {
      final planTitle =
          selectedPlan['title'] as String;

      final donnees = <String, dynamic>{
        'email': widget.email,
        'password': widget.password,
        'nomEntreprise': widget.nomEntreprise,
        'nomComplet': widget.nomComplet,
        'telephoneWhatsapp':
            widget.telephoneWhatsapp,
        'secteurNom': widget.secteurNom,
        'devise': widget.devise ?? 'FCFA',
        'typeEntreprise': widget.typeEntreprise,
        'planTitle': planTitle,
        'transactionId': result.transactionId,
      };

      await _apiService.savePendingRegistration(
        donnees,
      );

      final success =
          await _creerCompteAvecRetries(donnees);

      if (!mounted) return;

      if (success) {
        final formuleActivee =
            await _activerFormuleCoteServeur(
          planTitle: planTitle,
          transactionId: result.transactionId,
        );

        if (!mounted) return;

        await _finaliserSauvegarde(
          donnees,
          formuleActivee: formuleActivee,
        );

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compte créé et formule $planTitle '
              'activée ! Bienvenue sur Femi 🎉',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );
      } else {
        setState(() {
          _isLoading = false;
          _paiementEnAttenteDeCompte = true;
          _donneesEnAttente = donnees;
        });
      }

      return;
    }

    // Compte existant : activation de l'offre.
    final planTitle =
        selectedPlan['title'] as String;

    final formuleActivee =
        await _activerFormuleCoteServeur(
      planTitle: planTitle,
      transactionId: result.transactionId,
    );

    if (!formuleActivee) {
      await _finaliserSauvegarde(
        {
          'planTitle': planTitle,
          'transactionId': result.transactionId,
        },
        formuleActivee: false,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Formule ${selectedPlan['title']} '
          'activée avec succès !',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop(true);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_paiementEnAttenteDeCompte) {
      return _buildEcranRecuperation();
    }

    final selectedPlan =
        _plans[_selectedPlanIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.black87,
          ),
          onPressed: () => widget.isOnboarding
              ? Navigator.pop(context)
              : Navigator.pop(context, false),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (widget.targetFeature != null)
                      TargetFeatureBannerWidget(
                        targetFeature:
                            widget.targetFeature!,
                      ),

                    Row(
                      children:
                          List.generate(_plans.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index <
                                      _plans.length - 1
                                  ? 8.0
                                  : 0.0,
                            ),
                            child: PlanTabWidget(
                              plan: _plans[index],
                              isSelected:
                                  _selectedPlanIndex ==
                                      index,
                              onTap: () => setState(
                                () => _selectedPlanIndex =
                                    index,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    PlanDetailCardWidget(
                      plan: selectedPlan,
                    ),

                    const SizedBox(height: 24),

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
                      groupValue:
                          _selectedPaymentMethod,
                      icon: Icons.phone_android,
                      title: 'Mobile Money',
                      subtitle:
                          'Flooz, T-Money, Wave, MoMo',
                      onChanged: (val) {
                        if (val != null) {
                          setState(
                            () =>
                                _selectedPaymentMethod =
                                    val,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    PaymentOptionCardWidget(
                      index: 1,
                      groupValue:
                          _selectedPaymentMethod,
                      icon: Icons.credit_card,
                      title: 'Carte Bancaire',
                      subtitle:
                          'Visa, Mastercard',
                      onChanged: (val) {
                        if (val != null) {
                          setState(
                            () =>
                                _selectedPaymentMethod =
                                    val,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ======================================================
            // BOUTONS
            // ======================================================

            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset:
                        const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF8B5CF6),
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _gererPaiement(
                                selectedPlan,
                              ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              widget.isOnboarding
                                  ? 'Créer mon compte (${selectedPlan['title']} — ${selectedPlan['price']})'
                                  : 'Activer la formule ${selectedPlan['title']} (${selectedPlan['price']})',
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // ==================================================
                  // NOUVEAU BOUTON "PASSER"
                  // Affiché UNIQUEMENT pendant l'onboarding.
                  // ==================================================

                  if (widget.isOnboarding) ...[
                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : _passerAbonnement,
                        child: const Text(
                          'Passer',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Écran de récupération après paiement confirmé
  /// mais création du compte échouée.
  Widget _buildEcranRecuperation() {
    final transactionId =
        _donneesEnAttente?['transactionId']
            as String?;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Finalisation du compte',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 56,
              ),

              const SizedBox(height: 16),

              const Text(
                'Votre paiement a bien été confirmé, '
                'mais la création de votre compte a échoué '
                '(problème réseau ou serveur).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF444444),
                ),
              ),

              const SizedBox(height: 16),

              if (transactionId != null) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Référence de transaction',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transactionId,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                'Vos informations sont sauvegardées — '
                'vous ne serez pas débité une seconde fois '
                'en réessayant. Si le problème persiste, '
                'contactez le support en donnant cette référence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _reessayerCreationCompte,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1565D8),
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Réessayer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
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