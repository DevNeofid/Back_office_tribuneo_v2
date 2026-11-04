import 'package:flutter/material.dart';

import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/views/my_single_page.dart';

/// Bouton « + » d'ajout unitaire, puis, sous une barre de séparation, l'accès
/// à l'import de commerçants (menu « Import »).
///
/// Utilisé par les écrans Partenaires et Clients.
class AddOrImportButtons extends StatelessWidget {
  final VoidCallback onAdd;

  const AddOrImportButtons({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(onPressed: onAdd, child: const Icon(Icons.add)),
        const SizedBox(
          width: 140,
          child: Divider(height: 24, thickness: 1, color: kLBlue),
        ),
        ElevatedButton.icon(
            onPressed: () =>
                MySinglePage.maybeOf(context)?.openMenu('merchantImport'),
            icon: const Icon(Icons.upload_file),
            label: const Text('Importer des commerçants')),
      ],
    );
  }
}
