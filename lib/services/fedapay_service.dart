import 'dart:convert';
import 'package:http/http.dart' as http;

/// Résultat de l'appel à la mutation payWithFedaPay.
class FedaPayResult {
  final bool success;
  final String? paymentUrl;
  final String? transactionId;
  final String? message;

  FedaPayResult({
    required this.success,
    this.paymentUrl,
    this.transactionId,
    this.message,
  });
}

/// Service d'appel à l'endpoint GraphQL de paiement FedaPay
/// (voir doc interne "Endpoint pour le paiement" — Kossi ADANOU).
class FedaPayService {
  static const String _endpoint = 'https://immoaskprodapi.omnisoft.africa/api/v2';

  /// URL utilisée comme callback_url. FedaPay valide que callback_url est
  /// une URL http(s) bien formée (un schéma personnalisé comme
  /// "femiapp://..." est rejeté), donc on utilise une URL https classique.
  /// Elle n'a pas besoin de répondre réellement : la WebView interceptera
  /// la navigation vers cette URL AVANT qu'elle ne tente de la charger.
  /// C'est juste un identifiant fiable pour reconnaître "l'utilisateur a
  /// terminé le paiement, FedaPay le renvoie vers l'app".
  static const String callbackUrlPrefix = 'https://payment-callback.femi.app/return';

  /// Échappe une valeur en chaîne JSON valide (donc aussi valide en
  /// littéral de chaîne GraphQL), pour éviter tout souci avec des
  /// apostrophes/guillemets dans les noms, emails, etc.
  static String _esc(String value) => jsonEncode(value);

  /// Initie un paiement et renvoie l'URL vers laquelle rediriger
  /// l'utilisateur (page de paiement FedaPay), ou une erreur.
  Future<FedaPayResult> creerPaiement({
    required String description,
    required int amount,
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
    String countryCode = 'TG',
    String currency = 'XOF',
  }) async {
    final mutation = '''
      mutation {
        payWithFedaPay(input: {
          description: ${_esc(description)},
          country_code: ${_esc(countryCode)},
          amount: $amount,
          firstname: ${_esc(firstname)},
          lastname: ${_esc(lastname)},
          phone: ${_esc(phone)},
          callback_url: ${_esc(callbackUrlPrefix)},
          currency: ${_esc(currency)},
          email: ${_esc(email)}
        }) {
          transaction_id
          success
          message
          payment_url
          raw_response
        }
      }
    ''';

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'query': mutation}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return FedaPayResult(
          success: false,
          message: 'Erreur serveur de paiement (code ${response.statusCode}).',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);

      // Erreurs GraphQL (schéma/validation), distinctes des erreurs métier
      // renvoyées dans "success"/"message" par payWithFedaPay lui-même.
      if (body['errors'] != null) {
        final errors = body['errors'] as List;
        final firstMessage = errors.isNotEmpty ? errors.first['message'] : null;
        return FedaPayResult(
          success: false,
          message: firstMessage?.toString() ?? 'Erreur lors de la création du paiement.',
        );
      }

      final data = body['data']?['payWithFedaPay'];
      if (data == null) {
        return FedaPayResult(
          success: false,
          message: 'Réponse inattendue du serveur de paiement.',
        );
      }

      final bool success = data['success'] == true;
      final String? paymentUrl = data['payment_url'] as String?;

      if (!success || paymentUrl == null || paymentUrl.isEmpty) {
        return FedaPayResult(
          success: false,
          message: data['message']?.toString() ?? "Le paiement n'a pas pu être initié.",
        );
      }

      return FedaPayResult(
        success: true,
        paymentUrl: paymentUrl,
        transactionId: data['transaction_id']?.toString(),
        message: data['message']?.toString(),
      );
    } catch (e) {
      return FedaPayResult(
        success: false,
        message: 'Erreur réseau lors de la création du paiement : $e',
      );
    }
  }
}