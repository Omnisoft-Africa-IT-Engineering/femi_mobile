import 'package:flutter/material.dart';
import '../onboarding/company_info_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nomCompletController = TextEditingController();
  final TextEditingController _entrepriseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color _bgColor = Color(0xFFF7F9FC);
  static const Color _accentTeal = Color(0xFF80F2DD);
  static const Color _darkGreen = Color(0xFF0D5C52);
  static const Color _primaryBlue = Color(0xFF1565D8);

  @override
  void dispose() {
    _nomCompletController.dispose();
    _entrepriseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    final nom = _nomCompletController.text.trim();
    final entreprise = _entrepriseController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (nom.isEmpty || entreprise.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyInfoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _accentTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: _darkGreen,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildStepIndicator(currentStep: 1),
                const SizedBox(height: 24),

                const Center(
                  child: Text(
                    'Créer votre compte',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Commençons par vos informations personnelles',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Champ Nom complet
                const Text(
                  'Nom complet',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _nomCompletController,
                  hint: 'Ex: Jean-Baptiste',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // Champ Nom de l'entreprise
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
                  controller: _entrepriseController,
                  hint: 'Ex: Komi Services',
                  icon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 20),

                // Champ Email
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _emailController,
                  hint: 'exemple@email.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Champ Mot de passe
                const Text(
                  'Mot de passe',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 20),

                // Champ Confirmation mot de passe
                const Text(
                  'Confirmer le mot de passe',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _confirmPasswordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton Suivant
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Suivant',
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
                ),
                const SizedBox(height: 20),

                // Lien Se connecter
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'Déjà un compte ? ',
                        style:
                            TextStyle(color: Colors.grey[700], fontSize: 13),
                        children: const [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: _darkGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
    bool obscureText = false,
    Widget? suffixIcon,
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
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        ),
      ),
    );
  }
}