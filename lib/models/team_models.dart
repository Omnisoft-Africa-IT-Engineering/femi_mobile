/// Niveau d'accès : le gérant voit tout, l'employé a un menu réduit.
enum UserRole { gerant, employe }

class TeamMember {
  final String id;
  final String nom;
  final String contact; // e-mail ou téléphone
  final String poste; // libellé libre saisi par le gérant (ex : Serveuse, Employé 1)
  final UserRole role;
  final bool actif;
  final double ventesDuJour;

  const TeamMember({
    required this.id,
    required this.nom,
    required this.contact,
    this.poste = 'Employé',
    this.role = UserRole.employe,
    this.actif = true,
    this.ventesDuJour = 0,
  });

  TeamMember copyWith({bool? actif, String? poste}) => TeamMember(
    id: id,
    nom: nom,
    contact: contact,
    poste: poste ?? this.poste,
    role: role,
    actif: actif ?? this.actif,
    ventesDuJour: ventesDuJour,
  );
}