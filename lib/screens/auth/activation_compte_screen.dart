import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';

/// Écran utilisé par l'employé pour activer son compte avec le code reçu du patron.
class ActivationCompteScreen extends StatefulWidget {
  const ActivationCompteScreen({super.key});

  @override
  State<ActivationCompteScreen> createState() => _ActivationCompteScreenState();
}

class _ActivationCompteScreenState extends State<ActivationCompteScreen> {
  final FemiApiService _apiService = FemiApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _envoi = false;
  bool _masquer = true;
  String? _erreur;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _activer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    final res = await _apiService.activerCompte(
      email: _emailCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (res.containsKey('error')) {
      setState(() {
        _envoi = false;
        _erreur = res['error'].toString();
      });
      return;
    }

    setState(() => _envoi = false);

    // On renvoie l'e-mail et le mot de passe à l'écran de connexion,
    // qui se charge de connecter l'employé.
    Navigator.pop(context, <String, String>{
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activer mon compte',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saisissez votre e-mail, le code reçu de votre employeur '
                      'et choisissez votre mot de passe.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Champ obligatoire';
                    if (!s.contains('@') || !s.contains('.')) return 'E-mail invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: "Code d'activation (6 chiffres)"),
                  validator: (v) =>
                  (v == null || v.trim().length != 6) ? 'Le code contient 6 chiffres' : null,
                ),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _masquer,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(_masquer ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _masquer = !_masquer),
                    ),
                  ),
                  validator: (v) =>
                  (v == null || v.length < 8) ? '8 caractères minimum' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _masquer,
                  decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                  validator: (v) =>
                  v != _passwordCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 16),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _envoi ? null : _activer,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006654)),
                    child: _envoi
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text(
                      'Activer mon compte',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}