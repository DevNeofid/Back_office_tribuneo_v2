import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import 'package:flutter/material.dart';

import 'export_to_csv_helper_web.dart';

class ExportToCsvButton extends StatefulWidget {
  final Future<String?> Function()? fetchCsvData; // Changement de nom ici
  final String filename;
  final bool externalLoading;

  const ExportToCsvButton({
    super.key,
    this.fetchCsvData,
    this.filename = 'export.csv',
    this.externalLoading = false,
  });

  @override
  State<ExportToCsvButton> createState() => _ExportToCsvButtonState();
}

class _ExportToCsvButtonState extends State<ExportToCsvButton> {
  bool _loading = false;

  Future<void> _onPressed() async {
    setState(() => _loading = true);
    try {
      if (widget.fetchCsvData == null) {
        throw Exception('Aucune source fournie pour le CSV');
      }

      // On récupère directement le contenu du CSV (String)
      final String? csvData = await widget.fetchCsvData!();

      if (csvData == null || csvData.isEmpty) {
        throw Exception('Aucune donnée CSV reçue');
      }

      // On passe les données à notre nouvelle méthode
      downloadCsvFromString(csvData, widget.filename);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _loading || widget.externalLoading;

    // Action principale de l'écran : bouton orange du thème « Arc ».
    return FilledButton.icon(
      onPressed: isBusy ? null : _onPressed,
      icon: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: TribuneoLoader())
          : const Icon(Icons.download_rounded, size: 18),
      label: const Text('Exporter en CSV'),
    );
  }
}
