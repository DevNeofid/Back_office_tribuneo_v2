import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/bto_preview_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/partner_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/bank_account_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/addresses/address_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/addresses/update_address_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/bank_informations/bank_information_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/bank_informations/update_bank_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/hold_refund_dialog.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

/// « Prochain virement » : ce qui sera payé au prochain ordre de virement, par
/// commerçant et par demande, et ce qui sera écarté avec la raison.
///
/// L'aperçu (`GET /bto/preview`) est la seule source : aucun montant n'est calculé
/// ici et l'aperçu est rechargé après chaque action.
class NextTransferView extends StatefulWidget {
  const NextTransferView({super.key});

  @override
  State<NextTransferView> createState() => _NextTransferViewState();
}

class _NextTransferViewState extends State<NextTransferView> {
  final TransferOrderUseCase _transferOrderUseCase = TransferOrderUseCase();
  final BankAccountUseCase _bankAccountUseCase = BankAccountUseCase();
  final PartnerUseCase _partnerUseCase = PartnerUseCase();

  /// `null` si le chargement a échoué : on affiche alors le compte de l'aperçu,
  /// sans select, et l'API prend le compte `is_refund`.
  BankAccountsModel? _bankAccounts;
  BankAccountModel? _selectedBankAccount;

  BtoPreviewModel? _preview;

  /// Compte envoyé pour l'aperçu affiché : la génération envoie le même.
  String? _previewBankAccountCode;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isGenerating = false;

  /// Cartes commerçant dépliées (clé de [_merchantKey]).
  final Set<String> _expandedMerchants = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadBankAccounts();
    await _loadPreview();
  }

  Future<void> _loadBankAccounts() async {
    BankAccountsModel? accounts;
    try {
      accounts = await _bankAccountUseCase.getBankAccounts();
    } catch (_) {
      accounts = null;
    }
    if (!mounted) return;
    setState(() {
      _bankAccounts = accounts;
      _selectedBankAccount = (accounts?.refundSelectRequired ?? false)
          ? accounts!.byCode(_selectedBankAccount?.code) ??
              accounts.refundAccount ??
              accounts.accounts.first
          : null;
    });
  }

  /// Plusieurs comptes et pas de verrou : select présélectionné sur `is_refund`.
  /// Sinon le compte est seulement affiché et `bank_account` n'est pas envoyé.
  bool get _bankAccountSelectable =>
      _bankAccounts?.refundSelectRequired ?? false;

  String? get _requestedBankAccountCode =>
      _bankAccountSelectable ? _selectedBankAccount?.code : null;

  Future<void> _loadPreview({bool reloadedAccounts = false}) async {
    final String? bankAccountCode = _requestedBankAccountCode;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final BtoPreviewModel preview = await _transferOrderUseCase.getPreview(
          bankAccountCode: bankAccountCode);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _previewBankAccountCode = bankAccountCode;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // Liste des comptes périmée : on la recharge puis on réessaie une seule fois.
      if (!reloadedAccounts && _isBankAccountError(e.code)) {
        _showError(e.message);
        await _loadBankAccounts();
        if (!mounted) return;
        return _loadPreview(reloadedAccounts: true);
      }
      setState(() {
        _preview = null;
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _errorMessage = "Impossible de charger l'aperçu du prochain virement.";
        _isLoading = false;
      });
    }
  }

  bool _isBankAccountError(String? code) =>
      code == 'UNKNOWN_BANK_ACCOUNT' || code == 'BANK_ACCOUNT_LOCKED';

  void _showError(String message) {
    snackbarKey.currentState
        ?.showSnackBar(arcStatusSnackBar(message, error: true));
  }

  String _merchantLabel(String? code, String name) =>
      code == null || code.isEmpty ? name : '$code — $name';

  String _merchantKey(BtoMerchantToPay merchant) =>
      'merchant-${merchant.idEntity}-${merchant.entityCode}-${merchant.entityName}';

  /// « libellé — IBAN » du compte payeur de l'aperçu.
  String _payingAccountLabel(BtoPreviewModel preview) {
    final BtoPreviewBankAccount? account = preview.bankAccount;
    if (account == null) {
      return _bankAccounts?.refundAccount?.selectLabel ?? '—';
    }
    final String? iban = BankAccountModel.groupIban(account.iban);
    return iban == null ? account.label : '${account.label} — $iban';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _generate() async {
    final BtoPreviewModel? preview = _preview;
    if (_isGenerating ||
        _isLoading ||
        preview == null ||
        preview.totals.requestsToPay == 0) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _GenerationConfirmDialog(
        totals: preview.totals,
        payingAccount: _payingAccountLabel(preview),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isGenerating = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const LoadingDialog(
          loadingText: "Génération de l'ordre de virement..."),
    );

    // L'erreur est mise de côté puis traitée après le `finally` : le pop() qui ferme
    // le dialogue de chargement fermerait sinon le dialogue suivant à sa place.
    BtoGenerationResult? result;
    String? failureMessage;
    String? failureCode;
    try {
      result = await _transferOrderUseCase.generate(
          bankAccountCode: _previewBankAccountCode);
    } on ApiException catch (e) {
      failureMessage = e.message;
      failureCode = e.code;
    } catch (_) {
      failureMessage = "Erreur lors de la génération de l'ordre de virement.";
    } finally {
      navigatorKey.currentState?.pop();
    }

    if (!mounted) return;
    setState(() => _isGenerating = false);

    if (result == null) {
      _showError(failureMessage ??
          "Erreur lors de la génération de l'ordre de virement.");
      if (_isBankAccountError(failureCode)) await _loadBankAccounts();
      if (mounted) _loadPreview();
      return;
    }

    FileDownloader.downloadLargeFile(
        result.bytes,
        result.filename ?? 'BTO_${formatApiDate(DateTime.now())}',
        'application/zip',
        fileExtension: 'zip');
    _loadPreview();

    final int paid = result.requestsPaid ?? preview.totals.requestsToPay;
    final int excluded =
        result.requestsExcluded ?? preview.totals.requestsExcluded;
    final String? filename = result.filename;
    await showDialog(
      context: context,
      builder: (context) => ArcDialog(
        icon: Icons.check_rounded,
        tone: ArcTone.success,
        title: 'Ordre de virement généré',
        maxWidth: 520,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              'Ordre de virement généré : '
              '${plural(paid, 'demande payée', 'demandes payées')}. '
              'Transmettez le fichier .SCT à votre banque.'
              '${excluded > 0 ? '\n\nLa liste des demandes écartées est dans le fichier '
                  'REMBOURSEMENTS_ECARTES.csv du zip.' : ''}',
            ),
            if (filename != null && filename.isNotEmpty) ...[
              const SizedBox(height: 16),
              _FileChip(filename),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _hold(BtoMerchantToPay merchant, BtoRequestToPay request) async {
    final bool? done = await showDialog<bool>(
      context: context,
      builder: (context) => HoldRefundDialog(
        transactionNumber: request.transactionNumber,
        merchantLabel: _merchantLabel(merchant.entityCode, merchant.entityName),
        requestDate: formatFrenchDate(request.createdDate),
        amount: formatEuro(request.amount),
      ),
    );
    if (done == true && mounted) _loadPreview();
  }

  Future<void> _release(BtoExcludedRequest request) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ArcDialog(
        icon: Icons.play_arrow_rounded,
        tone: ArcTone.success,
        title: 'Libérer la demande ${request.transactionNumber}',
        maxWidth: 480,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Cette demande sera incluse dans le prochain virement.'),
            const SizedBox(height: 16),
            RefundRequestSummary(
              title: _merchantLabel(request.entityCode, request.entityName),
              transactionNumber: request.transactionNumber,
              date: formatFrenchDate(request.createdDate),
              amount: formatEuro(request.amount),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Libérer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _transferOrderUseCase.releaseRefund(request.transactionNumber);
      snackbarKey.currentState?.showSnackBar(arcStatusSnackBar(
          'Demande ${request.transactionNumber} libérée.'));
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Erreur lors de la libération de la demande.');
    }
    if (mounted) _loadPreview();
  }

  /// Ouvre directement les formulaires de la fiche du commerçant qui manquent.
  Future<void> _completeEntity(BtoExcludedRequest request) async {
    if (request.idEntity == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const LoadingDialog(
          loadingText: 'Chargement de la fiche du commerçant...'),
    );
    EntityModel? partner;
    try {
      final Map<int, dynamic> result = await _partnerUseCase.getPartners();
      final List<EntityModel> partners =
          (result[PartnerRepository.allPartnersKey] as List<EntityModel>?) ??
              [];
      partner = partners.where((p) => p.id == request.idEntity).firstOrNull;
    } catch (_) {
      partner = null;
    } finally {
      navigatorKey.currentState?.pop();
    }

    if (!mounted) return;
    if (partner == null) {
      _showError('Fiche du commerçant introuvable. '
          'Complétez-la depuis le menu Partenaires.');
      return;
    }

    final EntityModel entity = partner;
    bool changed = false;
    if (request.reasons.contains(BtoExcludedRequest.missingAddress)) {
      final bool? saved = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) => entity.address != null
            ? UpdateAddressForm(entity: entity)
            : AddressForm(entity: entity),
      );
      changed = changed || saved == true;
    }
    if (!mounted) return;
    if (request.reasons.contains(BtoExcludedRequest.missingBankDetails)) {
      final bool? saved = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) => entity.bankInformations != null
            ? UpadateBankInformationsForm(entity: entity)
            : BankInformationsForm(entity: entity),
      );
      changed = changed || saved == true;
    }
    if (changed && mounted) _loadPreview();
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final BtoPreviewModel? preview = _preview;
    final bool canGenerate = preview != null &&
        preview.totals.requestsToPay > 0 &&
        !_isGenerating &&
        !_isLoading;

    final List<Widget> body;
    if (preview == null && _isLoading) {
      body = const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (_errorMessage != null || preview == null) {
      body = [_buildError()];
    } else {
      body = [
        if (_isLoading)
          const LinearProgressIndicator(minHeight: 3)
        else
          const SizedBox(height: 3),
        const SizedBox(height: 8),
        _buildSummary(preview),
        const SizedBox(height: 24),
        if (preview.isEmpty)
          const ArcEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Aucune demande de remboursement en attente.',
          )
        else ...[
          _buildToPaySection(preview),
          const SizedBox(height: 24),
          _buildExcludedSection(preview),
        ],
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcPageHeader(
          eyebrow: 'Finance',
          title: 'Prochain virement',
          actions: [
            FilledButton.icon(
              onPressed: canGenerate ? _generate : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text("Générer l'ordre de virement"),
            ),
          ],
        ),
        ...body,
      ],
    );
  }

  Widget _buildError() {
    return ArcEmptyState(
      icon: Icons.error_outline_rounded,
      tone: ArcTone.danger,
      title: _errorMessage ??
          "Impossible de charger l'aperçu du prochain virement.",
      action: OutlinedButton.icon(
        onPressed: _isLoading ? null : _initialize,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Réessayer'),
      ),
    );
  }

  /// Périmètre, compte payeur et les quatre indicateurs de l'aperçu.
  Widget _buildSummary(BtoPreviewModel preview) {
    final BtoPreviewTotals totals = preview.totals;
    final String periodTo = formatFrenchDate(preview.periodTo);

    final List<Widget> tiles = [
      ArcKpiTile(
          label: 'Demandes à payer', value: '${totals.requestsToPay}', flat: true),
      ArcKpiTile(
          label: 'Commerçants', value: '${totals.merchantsToPay}', flat: true),
      ArcKpiTile(
          label: 'Montant à virer',
          value: formatEuro(totals.amountToTransfer),
          dark: true),
      ArcKpiTile(
          label: 'Demandes écartées',
          value: '${totals.requestsExcluded}',
          flat: true),
    ];

    return ArcCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final double accountWidth =
                constraints.maxWidth < 460 ? constraints.maxWidth : 460;
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 16,
              runSpacing: 16,
              children: [
                if (periodTo.isNotEmpty)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PÉRIMÈTRE', style: ArcText.label()),
                      const SizedBox(height: 2),
                      Text("Demandes faites jusqu'au $periodTo inclus",
                          style: ArcText.cardTitle().copyWith(fontSize: 16)),
                    ],
                  ),
                SizedBox(
                    width: accountWidth, child: _buildPayingAccount(preview)),
              ],
            );
          }),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth >= 720) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: tiles[i]),
                  ],
                ],
              );
            }
            final double width = (constraints.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final tile in tiles) SizedBox(width: width, child: tile),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPayingAccount(BtoPreviewModel preview) {
    final Widget label = Text('COMPTE PAYEUR', style: ArcText.label());

    if (!_bankAccountSelectable) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 6),
          SelectableText(_payingAccountLabel(preview),
              style: ArcText.data(color: kNavy900, fontWeight: FontWeight.w500)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: 6),
        DropdownButtonFormField<BankAccountModel>(
          // Recréé quand la sélection ou la liste des comptes change.
          key: ObjectKey(_selectedBankAccount),
          isExpanded: true,
          initialValue: _selectedBankAccount,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.expand_more_rounded),
          decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 11)),
          // Changer de compte recharge l'aperçu avec ce compte.
          onChanged: _isLoading || _isGenerating
              ? null
              : (BankAccountModel? account) {
                  if (account == null ||
                      account.code == _selectedBankAccount?.code) {
                    return;
                  }
                  setState(() => _selectedBankAccount = account);
                  _loadPreview();
                },
          items: _bankAccounts!.accounts
              .map((account) => DropdownMenuItem<BankAccountModel>(
                    value: account,
                    child: Text(account.selectLabel,
                        overflow: TextOverflow.ellipsis,
                        style: ArcText.data()),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildToPaySection(BtoPreviewModel preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcSectionTitle('À payer', count: '${preview.totals.requestsToPay}'),
        const SizedBox(height: 12),
        if (preview.toPay.isEmpty)
          const ArcEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Aucune demande prête à être payée',
          )
        else
          for (int i = 0; i < preview.toPay.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildMerchant(preview.toPay[i]),
          ],
      ],
    );
  }

  Widget _buildMerchant(BtoMerchantToPay merchant) {
    final String key = _merchantKey(merchant);
    final bool open = _expandedMerchants.contains(key);
    final String? code =
        (merchant.entityCode?.isEmpty ?? true) ? null : merchant.entityCode;

    return Container(
      key: ValueKey(key),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: open ? kNavy300 : kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: Material(
              color: kSurface,
              child: InkWell(
                onTap: () => setState(() {
                  if (!_expandedMerchants.remove(key)) {
                    _expandedMerchants.add(key);
                  }
                }),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      ArcAvatar(merchant.entityName, size: 40),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(merchant.entityName,
                                overflow: TextOverflow.ellipsis,
                                style: ArcText.cardTitle()),
                            if (code != null)
                              Text(code,
                                  style: ArcText.dataSmall(color: kText3)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(plural(merchant.requests.length, 'demande'),
                          style: ArcText.small().copyWith(fontSize: 13)),
                      const SizedBox(width: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 90),
                        child: Text(formatEuro(merchant.totalPayable),
                            textAlign: TextAlign.right,
                            style: ArcText.data(
                                    color: kNavy900,
                                    fontWeight: FontWeight.w500)
                                .copyWith(fontSize: 15)),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: open ? kNavy600 : kNavy50,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          open
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                          color: open ? Colors.white : kNavy600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (open) ...[
            const Divider(color: kNavy100),
            _ArcTable(
              DataTable(
                columns: [
                  const DataColumn(label: Text('Date')),
                  const DataColumn(
                      label: Text('Numéro'),
                      columnWidth: IntrinsicColumnWidth(flex: 1)),
                  const DataColumn(label: Text('Montant'), numeric: true),
                  const DataColumn(label: Text('Frais'), numeric: true),
                  const DataColumn(label: Text('Net'), numeric: true),
                  const DataColumn(label: Text('Justificatifs')),
                  DataColumn(
                      label: const Text('Action'),
                      headingRowAlignment: MainAxisAlignment.end),
                ],
                rows: merchant.requests
                    .map((request) => _requestRow(merchant, request))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  DataRow _requestRow(BtoMerchantToPay merchant, BtoRequestToPay request) {
    return DataRow(
      cells: [
        DataCell(SelectableText(formatFrenchDate(request.createdDate),
            style: ArcText.body(color: kText2).copyWith(fontSize: 13))),
        DataCell(SelectableText(request.transactionNumber,
            style: ArcText.data())),
        DataCell(Text(formatEuro(request.amount),
            style: ArcText.data(fontWeight: FontWeight.w500))),
        DataCell(Text(formatEuro(request.feesInclVat),
            style: ArcText.data(color: kText2))),
        DataCell(Text(formatEuro(request.totalPayable),
            style: ArcText.data(color: kNavy900, fontWeight: FontWeight.w500))),
        DataCell(request.hasDocuments
            ? Tooltip(
                message: request.proofOfReceiptNumber == null
                    ? 'Documents déjà émis'
                    : 'Documents déjà émis (${request.proofOfReceiptNumber})',
                child: const ArcPill('Déjà émis',
                    tone: ArcTone.success, icon: Icons.description_outlined),
              )
            : const ArcPill('À émettre')),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            style: _compactButtonStyle,
            onPressed: _isGenerating ? null : () => _hold(merchant, request),
            icon: const Icon(Icons.pause_rounded, size: 16),
            label: const Text('Mettre en attente'),
          ),
        )),
      ],
    );
  }

  Widget _buildExcludedSection(BtoPreviewModel preview) {
    final int count = preview.excluded.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcSectionTitle('Écartées',
            count: '$count',
            tone: count > 0 ? ArcTone.warning : ArcTone.neutral),
        const SizedBox(height: 4),
        Text(
            'Ces demandes ne seront pas payées dans ce virement. Elles seront '
            'reprises automatiquement dès que le problème sera résolu.',
            style: ArcText.small(color: kText3).copyWith(fontSize: 13)),
        const SizedBox(height: 12),
        if (preview.excluded.isEmpty)
          const _InlineEmptyState(
            icon: Icons.check_rounded,
            tone: ArcTone.success,
            title: 'Aucune demande écartée',
          )
        else
          ArcTableCard(
            child: _ArcTable(
              DataTable(
                dataRowMaxHeight: double.infinity,
                columns: [
                  const DataColumn(label: Text('Date')),
                  const DataColumn(label: Text('Numéro')),
                  const DataColumn(
                      label: Text('Commerçant'),
                      columnWidth: IntrinsicColumnWidth(flex: 1)),
                  const DataColumn(label: Text('Montant'), numeric: true),
                  const DataColumn(label: Text('Motifs')),
                  DataColumn(
                      label: const Text('Actions'),
                      headingRowAlignment: MainAxisAlignment.end),
                ],
                rows: preview.excluded.map(_excludedRow).toList(),
              ),
            ),
          ),
      ],
    );
  }

  DataRow _excludedRow(BtoExcludedRequest request) {
    final String? holdReason = request.holdReason?.trim();

    return DataRow(
      cells: [
        DataCell(SelectableText(formatFrenchDate(request.createdDate),
            style: ArcText.body(color: kText2).copyWith(fontSize: 13))),
        DataCell(SelectableText(request.transactionNumber,
            style: ArcText.data())),
        DataCell(SelectableText(
            _merchantLabel(request.entityCode, request.entityName),
            style: ArcText.body(color: kNavy900)
                .copyWith(fontSize: 13, fontWeight: FontWeight.w500))),
        DataCell(Text(formatEuro(request.amount),
            style: ArcText.data(fontWeight: FontWeight.w500))),
        DataCell(Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < request.reasons.length; i++)
                    request.reasons[i] == BtoExcludedRequest.onHold
                        ? ArcPill(request.reasonLabels[i],
                            tone: ArcTone.warning, icon: Icons.pause_rounded)
                        : ArcPill(request.reasonLabels[i],
                            tone: ArcTone.danger,
                            icon: Icons.error_outline_rounded),
                ],
              ),
              if (request.isOnHold &&
                  holdReason != null &&
                  holdReason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: SelectableText('« $holdReason »',
                      style: ArcText.small(color: kText3)
                          .copyWith(fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        )),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (request.needsEntityCompletion && request.idEntity != null)
                  OutlinedButton.icon(
                    style: _compactButtonStyle,
                    onPressed:
                        _isGenerating ? null : () => _completeEntity(request),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Compléter la fiche'),
                  ),
                if (request.isOnHold)
                  OutlinedButton.icon(
                    style: _compactButtonStyle,
                    onPressed: _isGenerating ? null : () => _release(request),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Libérer'),
                  ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

/// Boutons des lignes de tableau : hauteur compacte (36 px), texte 13 px.
final ButtonStyle _compactButtonStyle = OutlinedButton.styleFrom(
  minimumSize: const Size(0, kControlHeightCompact),
  padding: const EdgeInsets.symmetric(horizontal: 12),
  textStyle: ArcText.body().copyWith(fontSize: 13, fontWeight: FontWeight.w600),
);

/// Tableau pleine largeur, défilant horizontalement s'il ne tient pas.
class _ArcTable extends StatelessWidget {
  final DataTable table;
  const _ArcTable(this.table);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: table,
        ),
      ),
    );
  }
}

/// État vide compact, sur une ligne (section « Écartées »).
class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final ArcTone tone;
  final String title;
  const _InlineEmptyState(
      {required this.icon, required this.tone, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorderStrong),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: tone.background, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: tone.text),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(title,
              style: ArcText.body(color: kNavy900)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

/// Nom du fichier produit, dans un cartouche (dialogue de fin de génération).
class _FileChip extends StatelessWidget {
  final String filename;
  const _FileChip(this.filename);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kNavy50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        const Icon(Icons.insert_drive_file_outlined, size: 20, color: kNavy600),
        const SizedBox(width: 10),
        Expanded(
          child: SelectableText(filename,
              maxLines: 1, style: ArcText.data(color: kInk)),
        ),
      ]),
    );
  }
}

/// Confirmation de la génération : reprend les chiffres de l'en-tête de l'écran.
class _GenerationConfirmDialog extends StatelessWidget {
  final BtoPreviewTotals totals;
  final String payingAccount;

  const _GenerationConfirmDialog(
      {required this.totals, required this.payingAccount});

  @override
  Widget build(BuildContext context) {
    final int excluded = totals.requestsExcluded;

    return ArcDialog(
      icon: Icons.send_rounded,
      title: "Générer l'ordre de virement",
      maxWidth: 520,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${plural(totals.requestsToPay, 'demande')} pour '
              '${plural(totals.merchantsToPay, 'commerçant')}.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kNavy50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: ArcDefinitionList([
              (
                'Montant à virer',
                Text(formatEuro(totals.amountToTransfer),
                    style: ArcText.data(
                            color: kNavy900, fontWeight: FontWeight.w500)
                        .copyWith(fontSize: 15)),
              ),
              (
                'Compte payeur',
                SelectableText(payingAccount,
                    style: ArcText.data(color: kNavy900)),
              ),
            ], labelWidth: 120),
          ),
          if (excluded > 0) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 18, color: kWarningText),
                ),
                Expanded(
                  child: Text(excluded > 1
                      ? '$excluded demandes écartées ne seront pas payées.'
                      : '1 demande écartée ne sera pas payée.'),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Générer'),
        ),
      ],
    );
  }
}
