// Test de fumée (smoke test) : vérifie que l'application démarre sans
// planter. Les écrans réels de Femi (dashboard, auth, etc.) dépendent du
// backend et de l'état de connexion, donc on se contente ici de vérifier
// que le widget racine se construit correctement.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:femi_mobile/main.dart';

void main() {
  testWidgets('FemiApp démarre sans erreur', (WidgetTester tester) async {
    await tester.pumpWidget(const FemiApp());

    // Laisse le temps aux premiers appels asynchrones (ex: checkAuthStatus)
    // de se lancer sans faire planter le test.
    await tester.pump();

    // Vérifie simplement qu'un MaterialApp (ou équivalent) a bien été monté.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}