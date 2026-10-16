import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    snackbarKey.currentState?.showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: kRed,
        duration: const Duration(seconds: 8)));
  }

  String _merchantLabel(String? code, String name) =>
      code == null || code.isEmpty ? name : '$code — $name';

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
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordre de virement généré'),
        content: SizedBox(
          width: 480,
          child: SelectableText(
            'Ordre de virement généré : '
            '${plural(paid, 'demande payée', 'demandes payées')}. '
            'Transmettez le fichier .SCT à votre banque.'
            '${excluded > 0 ? '\n\nLa liste des demandes écartées est dans le fichier '
                'REMBOURSEMENTS_ECARTES.csv du zip.' : ''}',
          ),
        ),
        actions: [
          TextButton(
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
      ),
    );
    if (done == true && mounted) _loadPreview();
  }

  Future<void> _release(BtoExcludedRequest request) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Libérer la demande ${request.transactionNumber}'),
        content: const Text(
            'Cette demande sera incluse dans le prochain virement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Libérer',
                  style: TextStyle(
                      color: kBlue, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _transferOrderUseCase.releaseRefund(request.transactionNumber);
      snackbarKey.currentState?.showSnackBar(SnackBar(
          content: Text('Demande ${request.transactionNumber} libérée.'),
          backgroundColor: kGreen));
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

    Widget body;
    if (preview == null && _isLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: kOrange)),
      );
    } else if (_errorMessage != null || preview == null) {
      body = _buildError();
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isLoading)
            const LinearProgressIndicator(color: kOrange, minHeight: 3)
          else
            const SizedBox(height: 3),
          const SizedBox(height: 12),
          _buildHeader(preview),
          const SizedBox(height: 30),
          if (preview.isEmpty)
            _buildEmptyMessage('Aucune demande de remboursement en attente.')
          else ...[
            _buildToPaySection(preview),
            if (preview.excluded.isNotEmpty) ...[
              const SizedBox(height: 30),
              _buildExcludedSection(preview),
            ],
          ],
          const SizedBox(height: 50),
        ],
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: body,
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kRed, size: 40),
            const SizedBox(height: 12),
            SelectableText(
              _errorMessage ??
                  "Impossible de charger l'aperçu du prochain virement.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: kBlueEnd),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange, foregroundColor: kPWhite),
              onPressed: _isLoading ? null : _initialize,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(message,
              style: GoogleFonts.poppins(fontSize: 15, color: kBlueEnd)),
        ),
      ),
    );
  }

  Widget _buildHeader(BtoPreviewModel preview) {
    final BtoPreviewTotals totals = preview.totals;
    final String periodTo = formatFrenchDate(preview.periodTo);
    final bool canGenerate =
        totals.requestsToPay > 0 && !_isGenerating && !_isLoading;

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (periodTo.isNotEmpty)
              Text("Demandes faites jusqu'au $periodTo inclus",
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: kBlueEnd)),
            const SizedBox(height: 12),
            _buildPayingAccount(preview),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatTile(
                    label: 'Demandes à payer',
                    value: '${totals.requestsToPay}'),
                _StatTile(
                    label: 'Commerçants', value: '${totals.merchantsToPay}'),
                _StatTile(
                    label: 'Montant à virer',
                    value: formatEuro(totals.amountToTransfer)),
                _StatTile(
                  label: 'Demandes écartées',
                  value: '${totals.requestsExcluded}',
                  highlighted: totals.requestsExcluded > 0,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: kPWhite,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: canGenerate ? _generate : null,
                icon: const Icon(Icons.send),
                label: const Text("Générer l'ordre de virement"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayingAccount(BtoPreviewModel preview) {
    final TextStyle labelStyle =
        GoogleFonts.poppins(fontSize: 14, color: kGrey);

    if (!_bankAccountSelectable) {
      return SelectableText.rich(TextSpan(children: [
        TextSpan(text: 'Compte payeur : ', style: labelStyle),
        TextSpan(
            text: _payingAccountLabel(preview),
            style: labelStyle.copyWith(
                color: kBlueEnd, fontWeight: FontWeight.w600)),
      ]));
    }

    return Row(
      children: [
        Text('Compte payeur : ', style: labelStyle),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: DropdownButton<BankAccountModel>(
              isExpanded: true,
              value: _selectedBankAccount,
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
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: kBlueEnd)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, {String? help}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: kBlueEnd)),
          if (help != null) ...[
            const SizedBox(height: 4),
            Text(help,
                style: GoogleFonts.poppins(fontSize: 13, color: kGrey)),
          ],
        ],
      ),
    );
  }

  Widget _buildToPaySection(BtoPreviewModel preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('À payer'),
        if (preview.toPay.isEmpty)
          _buildEmptyMessage('Aucune demande prête à être payée')
        else
          ...preview.toPay.map(_buildMerchant),
      ],
    );
  }

  Widget _buildMerchant(BtoMerchantToPay merchant) {
    final TextStyle titleStyle = GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, color: kBlueEnd);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: kTransparent),
          child: ExpansionTile(
            key: ValueKey(
                'merchant-${merchant.idEntity}-${merchant.entityCode}-${merchant.entityName}'),
            iconColor: kBlue,
            collapsedIconColor: kBlue,
            title: Row(
              children: [
                Expanded(
                    child: Text(
                        _merchantLabel(merchant.entityCode, merchant.entityName),
                        style: titleStyle)),
                Text(plural(merchant.requests.length, 'demande'),
                    style: GoogleFonts.poppins(fontSize: 13, color: kGrey)),
                const SizedBox(width: 24),
                SizedBox(
                  width: 130,
                  child: Text(formatEuro(merchant.totalPayable),
                      textAlign: TextAlign.right, style: titleStyle),
                ),
              ],
            ),
            childrenPadding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.4),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(1.2),
                  5: FixedColumnWidth(40),
                  6: FlexColumnWidth(1.6),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(
                    horizontalInside:
                        BorderSide(color: kLBlue.withValues(alpha: 0.5))),
                children: [
                  _headerRow(const [
                    'Date',
                    'Numéro',
                    'Montant',
                    'Frais',
                    'Net',
                    '',
                    '',
                  ]),
                  ...merchant.requests
                      .map((request) => _requestRow(merchant, request)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _headerRow(List<String> labels) {
    return TableRow(
      decoration: BoxDecoration(color: kLBlue.withValues(alpha: 0.18)),
      children: labels
          .map((label) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kBlue)),
              ))
          .toList(),
    );
  }

  Widget _cell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: SelectableText(text,
          textAlign: align,
          style: GoogleFonts.poppins(fontSize: 13, color: kBlueEnd)),
    );
  }

  TableRow _requestRow(BtoMerchantToPay merchant, BtoRequestToPay request) {
    return TableRow(
      children: [
        _cell(formatFrenchDate(request.createdDate)),
        _cell(request.transactionNumber),
        _cell(formatEuro(request.amount)),
        _cell(formatEuro(request.feesInclVat)),
        _cell(formatEuro(request.totalPayable)),
        request.hasDocuments
            ? Tooltip(
                message: request.proofOfReceiptNumber == null
                    ? 'Documents déjà émis'
                    : 'Documents déjà émis (${request.proofOfReceiptNumber})',
                child: const Icon(Icons.description_outlined,
                    size: 18, color: kLBlue),
              )
            : const SizedBox.shrink(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: kBlue),
            onPressed: _isGenerating ? null : () => _hold(merchant, request),
            icon: const Icon(Icons.pause_circle_outline, size: 18),
            label: const Text('Mettre en attente'),
          ),
        ),
      ],
    );
  }

  Widget _buildExcludedSection(BtoPreviewModel preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Écartées',
          help: 'Ces demandes ne seront pas payées dans ce virement. Elles seront '
              'reprises automatiquement dès que le problème sera résolu.',
        ),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(2.4),
                5: FlexColumnWidth(1.6),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(
                  horizontalInside:
                      BorderSide(color: kLBlue.withValues(alpha: 0.5))),
              children: [
                _headerRow(const [
                  'Date',
                  'Numéro',
                  'Commerçant',
                  'Montant',
                  'Motifs',
                  '',
                ]),
                ...preview.excluded.map(_excludedRow),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TableRow _excludedRow(BtoExcludedRequest request) {
    final String? holdReason = request.holdReason?.trim();

    return TableRow(
      children: [
        _cell(formatFrenchDate(request.createdDate)),
        _cell(request.transactionNumber),
        _cell(_merchantLabel(request.entityCode, request.entityName)),
        _cell(formatEuro(request.amount)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...request.reasonLabels.map((label) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 6),
                          child: Icon(Icons.error_outline,
                              size: 15, color: kOrange),
                        ),
                        Expanded(
                          child: SelectableText(label,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: kBlueEnd)),
                        ),
                      ],
                    ),
                  )),
              if (request.isOnHold &&
                  holdReason != null &&
                  holdReason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 21, top: 2),
                  child: SelectableText('« $holdReason »',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: kGrey)),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (request.needsEntityCompletion && request.idEntity != null)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: kBlue),
                onPressed:
                    _isGenerating ? null : () => _completeEntity(request),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Compléter la fiche'),
              ),
            if (request.isOnHold)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: kBlue),
                onPressed: _isGenerating ? null : () => _release(request),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Libérer'),
              ),
          ],
        ),
      ],
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
    final TextStyle style = GoogleFonts.poppins(fontSize: 14, color: kBlack);
    final TextStyle strong = style.copyWith(fontWeight: FontWeight.w600);
    final int excluded = totals.requestsExcluded;

    return AlertDialog(
      title: const Text("Générer l'ordre de virement"),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${plural(totals.requestsToPay, 'demande')} pour '
                '${plural(totals.merchantsToPay, 'commerçant')}.',
                style: style),
            const SizedBox(height: 8),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Montant à virer : ', style: style),
              TextSpan(
                  text: formatEuro(totals.amountToTransfer), style: strong),
            ])),
            const SizedBox(height: 8),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Compte payeur : ', style: style),
              TextSpan(text: payingAccount, style: strong),
            ])),
            if (excluded > 0) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 18, color: kOrange),
                  ),
                  Expanded(
                    child: Text(
                        excluded > 1
                            ? '$excluded demandes écartées ne seront pas payées.'
                            : '1 demande écartée ne sera pas payée.',
                        style: style),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: kOrange, foregroundColor: kPWhite),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Générer'),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _StatTile(
      {required this.label, required this.value, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted
            ? kOrange.withValues(alpha: 0.12)
            : kLBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: highlighted ? kOrange : kTransparent, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: kGrey)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: highlighted ? kOrange : kBlueEnd)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(color: kTransparent, child: child),
      ),
    );
  }
}
