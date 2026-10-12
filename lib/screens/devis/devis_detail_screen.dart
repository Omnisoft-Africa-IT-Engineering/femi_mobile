import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/devis.dart';
import '../../services/devis_service.dart';
import 'devis_card.dart';

class DevisDetailScreen extends StatefulWidget {
  final Devis devis;

  const DevisDetailScreen({
    super.key,
    required this.devis,
  });

  @override
  State<DevisDetailScreen> createState() => _DevisDetailScreenState();
}

class _DevisDetailScreenState extends State<DevisDetailScreen> {
  final _service = DevisService.instance;

  late Devis _devis;
  bool _modifie = false;
  bool _chargementPdf = false;
  bool _chargementStatut = false;

  @override
  void initState() {
    super.initState();
    _devis = widget.devis;
  }

  Future<void> _changerStatut(StatutDevis nouveau) async {
    final id = _devis.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devis sans identifiant.')),
      );
      return;
    }

    if (_chargementStatut) return;

    setState(() => _chargementStatut = true);

    try {
      await _service.changerStatut(id, nouveau);

      if (!mounted) return;

      setState(() {
        _devis = _devis.copyWith(statut: nouveau);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut : ${nouveau.label}')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _chargementStatut = false);
      }
    }
  }

  Future<void> _apercuPdf() async {
    await _traiterPdf(partager: false);
  }

  Future<void> _partagerPdf() async {
    await _traiterPdf(partager: true);
  }

  Future<void> _traiterPdf({required bool partager}) async {
    if (_chargementPdf) return;

    final id = _devis.id;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de générer le PDF : devis sans identifiant.',
          ),
        ),
      );
      return;
    }

    setState(() => _chargementPdf = true);

    try {
      final bytes = await _service.telechargerPdf(id);

      if (bytes.isEmpty) {
        throw Exception('Le serveur a renvoyé un PDF vide.');
      }

      if (!mounted) return;

      final nomFichier = 'devis_${_devis.numeroDevis ?? id}.pdf';

      if (partager) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: nomFichier,
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Text(_devis.numeroDevis ?? 'Aperçu du devis'),
              ),
              body: PdfPreview(
                build: (_) async => bytes,
                pdfFileName: nomFichier,
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur PDF devis : $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            partager
                ? 'Impossible de partager le PDF. Vérifie la connexion et réessaie.'
                : 'Impossible d’afficher le PDF. Vérifie la connexion et réessaie.',
          ),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: partager ? _partagerPdf : _apercuPdf,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _chargementPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transitions = _devis.statut.transitionsAutorisees;

    return Scaffold(
      appBar: AppBar(
        title: Text(_devis.numeroDevis ?? 'Brouillon'),
        actions: [
          if (transitions.isNotEmpty)
            PopupMenuButton<StatutDevis>(
              tooltip: 'Changer le statut',
              icon: _chargementStatut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              onSelected: _chargementStatut ? null : _changerStatut,
              itemBuilder: (_) => [
                for (final s in transitions)
                  PopupMenuItem(
                    value: s,
                    child: Text(s.label),
                  ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DevisCard(
                  devis: _devis,
                  onChanged: (d) {
                    setState(() {
                      _devis = d;
                      _modifie = true;
                    });
                  },
                  onApercuPdf: _chargementPdf ? null : _apercuPdf,
                  onPartager: _chargementPdf ? null : _partagerPdf,
                ),
                if (_modifie)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Modifications des lignes non enregistrées côté serveur. '
                      'Le PDF reflète encore la version serveur.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
          if (_chargementPdf)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Préparation du PDF...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}