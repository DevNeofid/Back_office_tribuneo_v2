import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/core/utils/idempotency_key.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_import_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_import/merchant_import_grid.dart';

/// Import assisté des commerçants, ouvert en plein écran depuis « Partenaires ».
///
/// Premier état : la liste des lots ; un lot ouvert affiche sa grille de
/// relecture. Retourne `true` à la fermeture si au moins un commerçant a été
/// importé (la liste des partenaires est alors à recharger).
class MerchantImportView extends StatefulWidget {
  const MerchantImportView({super.key});

  @override
  State<MerchantImportView> createState() => _MerchantImportViewState();
}

class _MerchantImportViewState extends State<MerchantImportView> {
  final MerchantImportUseCase _useCase = MerchantImportUseCase();
  final PendingIdempotencyKey _createKey = PendingIdempotencyKey();
  final GlobalKey<MerchantImportGridState> _gridKey =
      GlobalKey<MerchantImportGridState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const int _pageSize = 20;

  List<MerchantImportBatch> _batches = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _loadError;

  MerchantImportBatch? _openBatch;
  bool _hasImported = false;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = _batches.isEmpty;
      _loadError = null;
    });
    try {
      final List<MerchantImportBatch> batches =
          await _useCase.getBatches(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _batches = batches;
        _hasMore = batches.length == _pageSize;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_batches.isEmpty) _loadError = e.message;
      });
      if (_batches.isNotEmpty) _snack(e.message, kRed);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final List<MerchantImportBatch> batches =
          await _useCase.getBatches(limit: _pageSize, offset: _batches.length);
      if (!mounted) return;
      setState(() {
        _batches = [..._batches, ...batches];
        _hasMore = batches.length == _pageSize;
      });
    } on ApiException catch (e) {
      _snack(e.message, kRed);
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _createFromFile() async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    final PlatformFile? file = picked?.files.first;
    if (file == null || !mounted) return;
    if (file.bytes == null || file.bytes!.isEmpty) {
      _snack('Veuillez importer un fichier valide', kRed);
      return;
    }

    final String fileBase64 = base64Encode(file.bytes!);
    final String key = _createKey.keyFor('${file.name}|$fileBase64');
    try {
      final MerchantImportBatch batch = await LoadingDialog.run(
          context,
          'Lecture du fichier…',
          () => _useCase.createFromFile(
              fileName: file.name,
              fileBase64: fileBase64,
              idempotencyKey: key));
      _createKey.clear();
      if (!mounted) return;
      setState(() {
        _batches = [batch, ..._batches.where((b) => b.id != batch.id)];
        _openBatch = batch;
      });
    } on ApiException catch (e) {
      _createKey.onError(e.code);
      _snack(e.message, kRed);
      if (e.code == 'IDEMPOTENCY_REQUEST_IN_PROGRESS') {
        // Le premier envoi est encore traité : on relit la liste au lieu de
        // renvoyer le fichier.
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) await _loadBatches();
      }
    }
  }

  Future<void> _cancelBatch(MerchantImportBatch batch) async {
    final bool? confirmed = await confirmCancelBatch(context);
    if (confirmed != true || !mounted) return;
    try {
      await _useCase.cancel(batch.id);
      _snack('Lot abandonné.', kBlue);
    } on ApiException catch (e) {
      _snack(e.message, kRed);
    }
    if (mounted) await _loadBatches();
  }

  void _openGrid(MerchantImportBatch batch) {
    setState(() => _openBatch = batch);
  }

  void _backToList() {
    if (!mounted) return;
    setState(() => _openBatch = null);
    _loadBatches();
  }

  Future<void> _close() async {
    if (_openBatch != null) {
      final bool canLeave =
          await _gridKey.currentState?.prepareToLeave() ?? true;
      if (!canLeave) return;
    }
    if (mounted) Navigator.of(context).pop(_hasImported);
  }

  void _snack(String message, Color color) {
    _messengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 6)));
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Messager propre à la vue : ceux de l'application s'afficheraient sous ce
    // dialogue plein écran.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: ScaffoldMessenger(
        key: _messengerKey,
        child: Scaffold(
          backgroundColor: kPLGrey,
          appBar: AppBar(
            backgroundColor: kBlue,
            foregroundColor: kWhite,
            automaticallyImplyLeading: false,
            title: Text('Import de commerçants',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600, color: kWhite)),
            actions: [
              IconButton(
                tooltip: 'Fermer',
                onPressed: _close,
                icon: const Icon(Icons.close),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _openBatch != null
              ? MerchantImportGrid(
                  key: _gridKey,
                  batch: _openBatch!,
                  onBack: _backToList,
                  onImported: () => _hasImported = true,
                )
              : _buildBatchList(),
        ),
      ),
    );
  }

  Widget _buildBatchList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: kPWhite,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    onPressed: _createFromFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Nouveau lot depuis un fichier'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _loadBatches,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Recharger'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFileModel(),
              const SizedBox(height: 24),
              _buildBatchTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileModel() {
    final TextStyle text = GoogleFonts.poppins(fontSize: 13, color: kBlueEnd);
    final TextStyle bold = text.copyWith(fontWeight: FontWeight.w600);
    Widget bullet(String title, String body) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '• $title ', style: bold),
            TextSpan(text: body, style: text),
          ])),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: kBlue, size: 20),
              const SizedBox(width: 8),
              Text('Modèle de fichier',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: kBlue)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              'Fichier .csv (séparateur ;) ou .xlsx, 2 000 lignes au plus, '
              'même modèle que l\'import de commerçants existant.',
              style: text),
          bullet(
              'Colonnes reconnues par leur nom d\'en-tête :',
              'code, name, email, type, siret, phone, contact_phone, street, '
                  'zip, city, country, lat, lng, activity_sectors, '
                  'intracommunity_vat_number, iban, bic, key, account_number.'),
          bullet(
              'Colonne absente des en-têtes :',
              'elle est lue à sa position — code (0), nom (1), email (2), '
                  'type (4), SIRET (5), ville (6), téléphone de contact (7), '
                  'téléphone (8), clé RIB (10), IBAN (14), BIC (15). Le fichier '
                  'doit donc suivre le modèle.'),
          bullet(
              'Type :',
              '« commerçant adhérent » ou partner pour un commerçant ; vide = '
                  'commerçant.'),
        ],
      ),
    );
  }

  Widget _buildBatchTable() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: kBlue)),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
            child: SelectableText(_loadError!,
                style: GoogleFonts.poppins(color: kRed))),
      );
    }
    if (_batches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
            child: Text('Aucun lot pour ce réseau.',
                style: GoogleFonts.poppins(color: kGrey))),
      );
    }

    Widget header(String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kWhite)),
        );
    Widget cell(String text, {Color color = kBlueEnd}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Text(text,
              style: GoogleFonts.poppins(fontSize: 13, color: color)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(110),
            1: FlexColumnWidth(220),
            2: FlexColumnWidth(150),
            3: FlexColumnWidth(380),
            4: FlexColumnWidth(220),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
              horizontalInside:
                  BorderSide(color: kLBlue.withValues(alpha: 0.5))),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: kBlue),
              children: ['Date', 'Source', 'Statut', 'Avancement', 'Action']
                  .map(header)
                  .toList(),
            ),
            for (int i = 0; i < _batches.length; i++)
              TableRow(
                decoration: BoxDecoration(
                    color: i.isOdd ? kLBlue.withValues(alpha: 0.10) : kPWhite),
                children: [
                  cell(formatFrenchDate(_batches[i].createdDate)),
                  cell(_batches[i].source ?? '—'),
                  cell(_batches[i].statusLabel,
                      color: _statusColor(_batches[i])),
                  cell(_batches[i].progressLabel),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => _openGrid(_batches[i]),
                          child: const Text('Ouvrir'),
                        ),
                        if (_batches[i].isEditable)
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: kRed),
                            onPressed: () => _cancelBatch(_batches[i]),
                            child: const Text('Abandonner'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (_hasMore) ...[
          const SizedBox(height: 12),
          Center(
            child: _isLoadingMore
                ? const CircularProgressIndicator(color: kBlue)
                : TextButton(
                    onPressed: _loadMore,
                    child: const Text('Afficher plus de lots'),
                  ),
          ),
        ],
      ],
    );
  }

  Color _statusColor(MerchantImportBatch batch) {
    switch (batch.status) {
      case MerchantImportBatch.statusReview:
        return kOrange;
      case MerchantImportBatch.statusDone:
        return kGreen;
      case MerchantImportBatch.statusFailed:
        return kRed;
      case MerchantImportBatch.statusCancelled:
        return kGrey;
      default:
        return kBlue;
    }
  }
}
