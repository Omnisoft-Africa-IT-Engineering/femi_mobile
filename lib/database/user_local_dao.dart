import 'package:sqflite/sqflite.dart';

import '../models/local_user.dart';
import 'app_database.dart';

class UserLocalDao {
  UserLocalDao._();

  static final UserLocalDao instance = UserLocalDao._();

  /// Enregistre ou met à jour l'utilisateur local.
  Future<void> saveUser(LocalUser user) async {
    final db = await AppDatabase.instance.database;

    await db.insert(
      'user_cache',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère l'utilisateur enregistré localement.
  Future<LocalUser?> getUser() async {
    final db = await AppDatabase.instance.database;

    final results = await db.query(
      'user_cache',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return LocalUser.fromMap(results.first);
  }

  /// Supprime l'utilisateur local.
  Future<void> deleteUser() async {
    final db = await AppDatabase.instance.database;

    await db.delete(
      'user_cache',
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Vérifie si un utilisateur est déjà enregistré localement.
  Future<bool> hasUser() async {
    final user = await getUser();
    return user != null;
  }
}