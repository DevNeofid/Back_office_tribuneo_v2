import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return ElevatedButton(
      onPressed: isBusy ? null : _onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor: kBlue,
        foregroundColor: kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
          : const Text('Exporter en CSV'),
    );
  }
}
