class LocalUser {
  final int id;
  final String? username;
  final String? companyName;
  final bool isPro;
  final String? plan;
  final DateTime? updatedAt;

  const LocalUser({
    this.id = 1,
    this.username,
    this.companyName,
    this.isPro = false,
    this.plan,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'company_name': companyName,
      'is_pro': isPro ? 1 : 0,
      'plan': plan,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'] as int? ?? 1,
      username: map['username'] as String?,
      companyName: map['company_name'] as String?,
      isPro: (map['is_pro'] as int? ?? 0) == 1,
      plan: map['plan'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }
}