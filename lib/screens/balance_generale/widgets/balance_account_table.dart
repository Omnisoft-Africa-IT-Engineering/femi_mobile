import 'package:flutter/material.dart';

/// Une ligne de compte pour un tableau de balance comptable.
class BalanceRowData {
  final String numero;
  final String libelle;
  final String debit;
  final String credit;
  final String solde;
  final bool soldeDebiteur; // true = solde débiteur, false = créditeur

  const BalanceRowData({
    required this.numero,
    required this.libelle,
    required this.debit,
    required this.credit,
    required this.solde,
    this.soldeDebiteur = true,
  });
}

/// Carte affichant l'en-tête de colonnes + la liste des lignes de compte.
class BalanceAccountTable extends StatelessWidget {
  final List<BalanceRowData> rows;

  const BalanceAccountTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeaderRow(),
          const Divider(height: 1),
          ...rows.map((row) => _buildDataRow(row)),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'Compte',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Débit',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Crédit',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Solde',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BalanceRowData row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.numero,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      row.libelle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.debit,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.credit,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.solde,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: row.soldeDebiteur
                        ? const Color(0xFF1B75BC)
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade100, height: 1),
        ],
      ),
    );
  }
}