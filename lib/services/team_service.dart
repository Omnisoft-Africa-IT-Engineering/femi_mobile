import 'package:flutter/foundation.dart';
import '../models/team_models.dart';

class TeamException implements Exception {
  final String message;
  TeamException(this.message);
  @override
  String toString() => message;
}

/// Service SIMULÉ (données en mémoire), comme pour les devis.
/// À remplacer par de vrais appels API quand les endpoints seront prêts.
class TeamService extends ChangeNotifier {
  TeamService._();
  static final TeamService instance = TeamService._();

  static const String posteParDefaut = 'Employé';

  final List<TeamMember> _members = [
    const TeamMember(
        id: '1',
        nom: 'Afi Mensah',
        contact: '+228 90 00 00 01',
        poste: 'Serveuse',
        ventesDuJour: 45000),
    const TeamMember(
        id: '2',
        nom: 'Kossiwa Adjovi',
        contact: '+228 90 00 00 02',
        poste: 'Employé 1',
        ventesDuJour: 32500),
  ];

  List<TeamMember> get members => List.unmodifiable(_members);

  Future<void> addMember({
    required String nom,
    required String contact,
    required String motDePasse, // non utilisé dans la simulation
    String poste = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existe = _members
        .any((m) => m.contact.trim().toLowerCase() == contact.trim().toLowerCase());
    if (existe) throw TeamException('Un employé avec ce contact existe déjà.');
    _members.add(TeamMember(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nom: nom.trim(),
      contact: contact.trim(),
      poste: poste.trim().isEmpty ? posteParDefaut : poste.trim(),
    ));
    notifyListeners();
  }

  Future<void> updatePoste(String id, String poste) async {
    final i = _members.indexWhere((m) => m.id == id);
    if (i == -1) return;
    _members[i] = _members[i]
        .copyWith(poste: poste.trim().isEmpty ? posteParDefaut : poste.trim());
    notifyListeners();
  }

  Future<void> setActif(String id, bool actif) async {
    final i = _members.indexWhere((m) => m.id == id);
    if (i == -1) return;
    _members[i] = _members[i].copyWith(actif: actif);
    notifyListeners();
  }
}