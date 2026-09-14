import 'package:flutter/material.dart';
import '../../states/auth_state.dart';

/// Étape 2 de l'onboarding — Informations sur l'entreprise.
/// Finalise la création du compte (Entreprise + Utilisateur) en combinant
/// les données de cet écran avec celles transmises depuis SignUpScreen.
class CompanyInfoScreen extends StatefulWidget {
  final String nomComplet;
  final String nomEntrepriseInitial;
  final String email;
  final String password;

  const CompanyInfoScreen({
    super.key,
    required this.nomComplet,
    required this.nomEntrepriseInitial,
    required this.email,
    required this.password,
  });

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  late final TextEditingController _nomEntrepriseController;
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  String? _secteurActivite;
  String _typeActivite = 'Achat-Vente';
  String _formeJuridique = 'Entreprise individuelle';
  String _devise = 'FCFA';

  static const Color _bgColor = Color(0xFFF7F9FC);
  static const Color _primaryBlue = Color(0xFF1565D8);

  final List<String> _secteurs = const [
    'Commerce général',
    'Services',
    'Industrie / Production',
    'Autre',
  ];

  final List<String> _formesJuridiques = const [
    'Entreprise individuelle',
    'SARL',
    'SA',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    // Pré-rempli avec le nom saisi à l'étape 1, mais reste modifiable.
    _nomEntrepriseController = TextEditingController(text: widget.nomEntrepriseInitial);
  }

  @override
  void dispose() {
    _nomEntrepriseController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _terminerOnboarding() async {
    final nomEntreprise = _nomEntrepriseController.text.trim();
    if (nomEntreprise.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom de l\'entreprise est requis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Inscription réelle : email comme identifiant (username), cohérent
    // avec LoginAPIView qui accepte déjà l'email comme identifiant.
    final success = await AuthState.instance.register(
      username: widget.email,
      password: widget.password,
      nomEntreprise: nomEntreprise,
      nomComplet: widget.nomComplet,
      email: widget.email,
      telephoneWhatsapp: _telephoneController.text.trim().isEmpty
          ? null
          : _telephoneController.text.trim(),
      secteurNom: _secteurActivite,
      devise: _devise,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès ! Bienvenue sur Femi 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      // AuthGate (à la racine) écoute AuthState.instance.isLoggedIn et
      // affichera automatiquement MainNavigationScreen maintenant qu'il
      // est passé à true — mais comme ces écrans d'onboarding ont été
      // empilés par-dessus via Navigator.push, il faut vider la pile
      // pour que ce changement redevienne visible à l'écran.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final error = AuthState.instance.errorMessage.value ?? 'Une erreur est survenue.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                _buildStepIndicator(currentStep: 2),
                const SizedBox(height: 24),

                const Text(
                  'Votre entreprise',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Parlez-nous un peu de votre activité',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                const Text(
                  "Nom de l'entreprise",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _nomEntrepriseController,
                  hint: 'Ex: Komi Services',
                  icon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 20),

                const Text(
                  "Secteur d'activité",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDropdownField(
                  value: _secteurActivite,
                  hint: 'Sélectionnez un secteur',
                  icon: Icons.category_outlined,
                  items: _secteurs,
                  onChanged: (val) => setState(() => _secteurActivite = val),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Type d'activité",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Achat-Vente',
                        selected: _typeActivite == 'Achat-Vente',
                        onTap: () => setState(() => _typeActivite = 'Achat-Vente'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Dépôt-Vente',
                        selected: _typeActivite == 'Dépôt-Vente',
                        onTap: () => setState(() => _typeActivite = 'Dépôt-Vente'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'Personnel',
                        selected: _typeActivite == 'Personnel',
                        onTap: () => setState(() => _typeActivite = 'Personnel'),
                      ),
                    ),
                  ],
                ),
                if (_typeActivite == 'Personnel') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Idéal pour suivre vos propres dépenses, sans gestion d\'entreprise.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 20),

                const Text(
                  'Forme juridique',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDropdownField(
                  value: _formeJuridique,
                  hint: 'Sélectionnez une forme juridique',
                  icon: Icons.gavel_outlined,
                  items: _formesJuridiques,
                  onChanged: (val) => setState(() => _formeJuridique = val ?? _formeJuridique),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Adresse',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _adresseController,
                  hint: 'Ex: Rue des Fleurs, Quartier X',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ville',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputField(
                            controller: _villeController,
                            hint: 'Ex: Lomé',
                            icon: Icons.location_city_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Devise',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdownField(
                            value: _devise,
                            hint: 'Devise',
                            icon: Icons.attach_money,
                            items: const ['FCFA', 'EUR', 'USD'],
                            onChanged: (val) => setState(() => _devise = val ?? _devise),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Numéro de téléphone',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _telephoneController,
                  hint: 'Ex: +228 90 00 00 00',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),

                ValueListenableBuilder<bool>(
                  valueListenable: AuthState.instance.isLoading,
                  builder: (context, isLoading, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _terminerOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continuer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required int currentStep}) {
    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final active = step <= currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: step < 3 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? _primaryBlue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 0.5),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 0.5),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _primaryBlue : Colors.grey.shade300),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}