import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Affiche la page de paiement FedaPay (payment_url) dans une WebView
/// intégrée à l'app. Dès que la navigation tente d'aller vers une URL
/// commençant par [callbackUrlPrefix] (notre callback_url), on l'intercepte
/// AVANT qu'elle ne charge réellement quoi que ce soit, on lit le statut
/// dans les paramètres de l'URL, et on referme l'écran en renvoyant
/// true (paiement réussi) ou false (échec/annulation) via Navigator.pop.
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String callbackUrlPrefix;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.callbackUrlPrefix,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasReturned = false; // évite un double pop si onPageStarted + onNavigationRequest se déclenchent tous les deux

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.startsWith(widget.callbackUrlPrefix)) {
              _terminerAvecUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _terminerAvecUrl(String url) {
    if (_hasReturned) return;
    _hasReturned = true;

    final uri = Uri.parse(url);
    // FedaPay ajoute généralement un paramètre de statut à l'URL de
    // callback. On couvre les variantes les plus courantes ; si votre
    // backend Django vérifie aussi la transaction via un webhook FedaPay
    // côté serveur, ce sera une confirmation redondante mais plus sûre —
    // à ajouter plus tard si besoin.
    final status = (uri.queryParameters['status'] ??
            uri.queryParameters['transaction_status'] ??
            '')
        .toLowerCase();

    final success = status == 'approved' || status == 'success' || status == 'completed';

    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}