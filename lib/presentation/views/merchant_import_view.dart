import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/core/utils/idempotency_key.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_import_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/views/my_single_page.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_import/merchant_import_grid.dart';

/// Import assisté des commerçants : menu « Import » de `MySinglePage`, aussi
/// ouvert depuis les boutons d'import des écrans Partenaires et Clients.
///
/// Premier état : la liste des lots ; un lot ouvert affiche sa grille de
/// relecture. Quitter l'écran avec un lot ouvert attend la fin des
/// enregistrements (`MySinglePageState.setLeaveGuard`).
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
  MySinglePageState? _page;

  @override
  void initState() {
    super.initState();
    _page = MySinglePage.maybeOf(context);
    _page?.setLeaveGuard(_canLeave);
    _loadBatches();
  }

  @override
  void dispose() {
    _page?.clearLeaveGuard(_canLeave);
    super.dispose();
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

  /// Avant de changer d'écran : attend la fin des enregistrements du lot
  /// ouvert et avertit s'il reste des échecs.
  Future<bool> _canLeave() async {
    if (_openBatch == null) return true;
    return await _gridKey.currentState
            ?.prepareToLeave(actionLabel: 'Quitter') ??
        true;
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
    // Messager propre à la vue : les messages s'affichent dans la zone de
    // l'import.
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: kCanvas,
        body: _openBatch != null
            ? MerchantImportGrid(
                key: _gridKey,
                batch: _openBatch!,
                onBack: _backToList,
                onImported: () {},
              )
            : _buildBatchList(),
      ),
    );
  }

  Widget _buildBatchList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ArcPageHeader(
                eyebrow: 'Réseau',
                title: 'Import de commerçants',
                actions: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loadBatches,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Recharger'),
                  ),
                  FilledButton.icon(
                    onPressed: _createFromFile,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Nouveau lot depuis un fichier'),
                  ),
                ],
              ),
              _buildFileModel(),
              const SizedBox(height: 24),
              ArcTableCard(
                toolbar: const ArcSectionTitle('Lots'),
                child: _buildBatchTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileModel() {
    final TextStyle text = ArcText.body(color: kText2).copyWith(fontSize: 13);
    final TextStyle bold = text.copyWith(fontWeight: FontWeight.w600);
    Widget bullet(String title, String body) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '• $title ', style: bold),
            TextSpan(text: body, style: text),
          ])),
        );

    return ArcCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kNavy50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.upload_file_outlined, color: kNavy600),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modèle de fichier', style: ArcText.cardTitle()),
                  Text('.csv ou .xlsx · 2 000 lignes au plus',
                      style: ArcText.small()),
                ],
              )),
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
                style: ArcText.body(color: kDangerText))),
      );
    }
    if (_batches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
            child: Text('Aucun lot pour ce réseau.',
                style: ArcText.body(color: kText3))),
      );
    }

    Widget header(String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(label, style: ArcText.label()),
        );
    Widget cell(String text, {bool data = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Text(text,
              style: data
                  ? ArcText.dataSmall()
                  : ArcText.body().copyWith(fontSize: 13)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                    width:
                        constraints.maxWidth < 960 ? 960 : constraints.maxWidth,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(110),
                        1: FlexColumnWidth(220),
                        2: FlexColumnWidth(150),
                        3: FlexColumnWidth(380),
                        4: FlexColumnWidth(220),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: const TableBorder(
                          horizontalInside: BorderSide(color: kBorder)),
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: kSurface2),
                          children: [
                            'Date',
                            'Source',
                            'Statut',
                            'Avancement',
                            'Action'
                          ].map(header).toList(),
                        ),
                        for (int i = 0; i < _batches.length; i++)
                          TableRow(
                            decoration: BoxDecoration(
                                color: i.isOdd ? kSurface2 : kSurface),
                            children: [
                              cell(formatFrenchDate(_batches[i].createdDate)),
                              cell(_batches[i].source ?? '—', data: true),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ArcPill(_batches[i].statusLabel,
                                        tone: _statusTone(_batches[i]),
                                        icon: _batches[i].isDone
                                            ? Icons.check_circle_outline
                                            : Icons.info_outline_rounded)),
                              ),
                              cell(_batches[i].progressLabel),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    TextButton(
                                      onPressed: () => _openGrid(_batches[i]),
                                      child: const Text('Ouvrir'),
                                    ),
                                    if (_batches[i].isEditable)
                                      TextButton(
                                        style: TextButton.styleFrom(
                                            foregroundColor: kRed),
                                        onPressed: () =>
                                            _cancelBatch(_batches[i]),
                                        child: const Text('Abandonner'),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    )))),
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

  ArcTone _statusTone(MerchantImportBatch batch) {
    switch (batch.status) {
      case MerchantImportBatch.statusReview:
        return ArcTone.warning;
      case MerchantImportBatch.statusDone:
        return ArcTone.success;
      case MerchantImportBatch.statusFailed:
        return ArcTone.danger;
      case MerchantImportBatch.statusCancelled:
        return ArcTone.neutral;
      default:
        return ArcTone.info;
    }
  }
}
