/// Représente une transaction créée par l'agent Femi (Code HTTP 201)
class FemiTransaction {
  final String id;
  final String transactionType; // "RECETTE" ou "DEPENSE"
  final String? amountHt;
  final String taxAmount;
  final String amountTtc;
  final String currency;
  final String category;
  final String? vendorOrClient;
  final String paymentMethod;
  final String? transactionDate;
  final String description;
  final double confidenceScore;
  final String source;
  final String? rawInputText;
  final String? receiptImage;
  final String createdAt;
  final String entreprise;

  FemiTransaction({
    required this.id,
    required this.transactionType,
    this.amountHt,
    required this.taxAmount,
    required this.amountTtc,
    required this.currency,
    required this.category,
    this.vendorOrClient,
    required this.paymentMethod,
    this.transactionDate,
    required this.description,
    required this.confidenceScore,
    required this.source,
    this.rawInputText,
    this.receiptImage,
    required this.createdAt,
    required this.entreprise,
  });

  factory FemiTransaction.fromJson(Map<String, dynamic> json) {
    return FemiTransaction(
      id: json['id'] ?? '',
      transactionType: json['transaction_type'] ?? 'DEPENSE',
      amountHt: json['amount_ht'],
      taxAmount: json['tax_amount'] ?? '0',
      amountTtc: json['amount_ttc'] ?? '0',
      currency: json['currency'] ?? 'XOF',
      category: json['category'] ?? '',
      vendorOrClient: json['vendor_or_client'],
      paymentMethod: json['payment_method'] ?? 'CASH',
      transactionDate: json['transaction_date'],
      description: json['description'] ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] ?? 'MOBILE',
      rawInputText: json['raw_input_text'],
      receiptImage: json['receipt_image'],
      createdAt: json['created_at'] ?? '',
      entreprise: json['entreprise'] ?? '',
    );
  }
}

/// Structure englobante pour gérer les réponses 200 (Chat/Discussion) et 201 (Transaction enregistrée)
class FemiAgentResponse {
  final int statusCode;
  final String? message;
  final FemiTransaction? transaction;

  FemiAgentResponse({
    required this.statusCode,
    this.message,
    this.transaction,
  });

  bool get isTransaction => statusCode == 201 && transaction != null;
}