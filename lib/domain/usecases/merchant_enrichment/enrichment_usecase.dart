import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/utils/idempotency_key.dart';
import '../../models/merchant_import_row_model.dart';
import '../../models/merchant_enrichment/enrichment_models.dart';
import '../../repositories/merchant_enrichment/enrichment_repository.dart';

const merchantEnrichmentEnabled =
    bool.fromEnvironment('MERCHANT_ENRICHMENT_ENABLED', defaultValue: false);

/// Separate session for one tenant/batch. No validation/import operation here.
class EnrichmentUseCase extends ChangeNotifier {
  final EnrichmentRepository repository;
  final int batchId;
  final bool enabled;
  final MerchantImportRow? Function(int) currentRow;
  final bool Function() batchEditable;
  final void Function(List<MerchantImportRow>) replaceRows;
  final Future<List<MerchantImportRow>> Function() reloadRows;
  final Duration pollInterval;
  final int maxPolls;
  final _startKey = PendingIdempotencyKey();
  final Map<String, PendingIdempotencyKey> _applyKeys = {};
  final Set<String> _invalidProposals = {};
  String? _tenant;
  Timer? _timer;
  int _readEpoch = 0, _polls = 0;
  bool _disposed = false;
  bool busy = false, paused = true;
  String? message;
  EnrichmentCapability? capability;
  EnrichmentJob? job;
  EnrichmentPage<EnrichmentProposal>? page;
  EnrichmentPage<EnrichmentJob>? history;

  EnrichmentUseCase(
      {required this.repository,
      required this.batchId,
      required this.currentRow,
      required this.batchEditable,
      required this.replaceRows,
      required this.reloadRows,
      this.enabled = merchantEnrichmentEnabled,
      this.pollInterval = const Duration(seconds: 3),
      this.maxPolls = 100});

  bool get available => enabled && capability?.available == true;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _checkTenant() async {
    final tenant = await repository.transport.currentTenant();
    if (_disposed || tenant.isEmpty || (_tenant != null && _tenant != tenant)) {
      pause();
      throw const EnrichmentException();
    }
    _tenant ??= tenant;
  }

  Future<void> initialize() async {
    if (!enabled || busy || _disposed) return;
    await _run(() async {
      capability = null;
      final result = await repository.capabilities(_tenant!);
      await _checkTenant();
      if (!_disposed) capability = result;
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (busy || _disposed) return;
    busy = true;
    message = null;
    _emit();
    try {
      await _checkTenant();
      await operation();
    } on EnrichmentException catch (e) {
      if (!_disposed) message = e.toString();
    } catch (_) {
      if (!_disposed) message = const EnrichmentException().toString();
    } finally {
      busy = false;
      _emit();
    }
  }

  static bool eligible(MerchantImportRow row) =>
      row.isPending && row.textOf('type') == 'partner';

  Future<void> start(List<int> ids) async {
    if (!available || !batchEditable() || busy || job?.active == true) return;
    final sorted = ids.toSet().toList()..sort();
    if (sorted.isEmpty ||
        sorted.length > capability!.maxRows ||
        sorted.any(
            (id) => currentRow(id) == null || !eligible(currentRow(id)!))) {
      message = 'Sélectionnez explicitement des lignes commerçants à relire.';
      _emit();
      return;
    }
    final body = <String, dynamic>{'row_ids': sorted, 'mode': 'missing_only'};
    await _run(() async {
      final key = _startKey.keyFor(jsonEncode([_tenant, batchId, body]));
      try {
        final result = await repository.start(_tenant!, batchId, body, key);
        await _checkTenant();
        if (_disposed) return;
        job = result;
        page = null;
        _startKey.clear();
      } on EnrichmentException catch (e) {
        _startKey.onError(e.status >= 500 ? null : e.code);
        rethrow;
      }
    });
    if (!_disposed && job != null) await resume();
  }

  /// Lists persisted jobs at every reopen. Select an older job for its history.
  Future<void> resume({int historyOffset = 0, String? jobId}) async {
    if (!available || busy || _disposed) return;
    pause();
    final epoch = _readEpoch;
    await _run(() async {
      final result =
          await repository.jobs(_tenant!, batchId, offset: historyOffset);
      await _checkTenant();
      if (_disposed || epoch != _readEpoch) return;
      history = result;
      final selected = jobId == null
          ? (result.items.isEmpty ? null : result.items.first)
          : result.items.where((j) => j.id == jobId).firstOrNull;
      if (selected == null) {
        job = null;
      } else {
        _acceptJob(selected);
      }
      page = null;
      paused = false;
      _polls = 0;
      if (job != null) await _read(epoch, offset: 0);
    });
    _schedule();
  }

  void _acceptJob(EnrichmentJob next) {
    final previous = job;
    if (previous != null &&
        previous.id == next.id &&
        (next.done < previous.done ||
            next.updatedAt.compareTo(previous.updatedAt) < 0 ||
            (!previous.active && next.active))) return;
    job = next;
  }

  Future<void> _read(int epoch, {required int offset}) async {
    final selected = job;
    if (selected == null) return;
    final next = await repository.read(_tenant!, batchId, selected.id);
    if (_disposed || epoch != _readEpoch) return;
    final proposals = await repository.proposals(_tenant!, batchId, selected.id,
        offset: offset);
    await _checkTenant();
    if (_disposed || epoch != _readEpoch) return;
    _acceptJob(next);
    page = proposals;
  }

  Future<void> readPage(int offset) async {
    if (!available || busy || offset < 0 || _disposed) return;
    final epoch = _readEpoch;
    await _run(() => _read(epoch, offset: offset));
  }

  void _schedule() {
    _timer?.cancel();
    if (_disposed || paused || job?.active != true) return;
    if (_polls >= maxPolls || message != null) {
      pause();
      message ??=
          'Lecture en pause. Reprenez la lecture pour actualiser la recherche.';
      _emit();
      return;
    }
    _timer = Timer(pollInterval, () async {
      if (busy) {
        _schedule();
        return;
      }
      _polls++;
      await readPage(page?.offset ?? 0);
      _schedule();
    });
  }

  void pause({bool notify = true}) {
    _timer?.cancel();
    _timer = null;
    paused = true;
    _readEpoch++;
    if (notify) _emit();
  }

  Future<void> cancel() async {
    if (!available || busy || job?.active != true) return;
    pause();
    await _run(() async {
      final result = await repository.cancel(_tenant!, batchId, job!.id);
      await _checkTenant();
      if (!_disposed) _acceptJob(result);
      // Published proposals remain readable, even if cancellation raced completion.
      if (!_disposed) await _read(_readEpoch, offset: page?.offset ?? 0);
    });
  }

  static bool empty(dynamic value) =>
      value == null || (value is String && value.trim().isEmpty);
  static const fields = {
    'name',
    'siret',
    'street',
    'zip',
    'city',
    'country',
    'naf',
    'lat',
    'lng'
  };
  Set<String> applicable(
      EnrichmentProposal proposal, EnrichmentCandidate candidate) {
    final row = currentRow(proposal.rowId);
    if (!batchEditable() ||
        row == null ||
        !eligible(row) ||
        row.version != proposal.baseVersion ||
        !{'matched', 'ambiguous', 'address_only'}.contains(proposal.state) ||
        proposal.batchId != batchId ||
        _invalidProposals.contains(proposal.id) ||
        proposal.jobId != job?.id ||
        !proposal.candidates.any((c) => c.id == candidate.id)) return {};
    final currentSiret =
        MerchantImportRow.normalized('siret', row.valueOf('siret'));
    final candidateSiret = MerchantImportRow.normalized(
        'siret', candidate.siret ?? candidate.fields['siret']);
    if (currentSiret.isNotEmpty &&
        candidateSiret.isNotEmpty &&
        currentSiret != candidateSiret) return {};
    final result = candidate.fields.keys
        .where((field) =>
            fields.contains(field) &&
            empty(row.valueOf(field)) &&
            !empty(candidate.fields[field]) &&
            candidate.sources.containsKey(field))
        .toSet();
    final lat = candidate.fields['lat'], lng = candidate.fields['lng'];
    if (!result.containsAll({'lat', 'lng'}) ||
        lat is! num ||
        lng is! num ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      result.removeAll({'lat', 'lng'});
    }
    return result;
  }

  Future<bool> apply(EnrichmentProposal proposal, EnrichmentCandidate candidate,
      Set<String> selected,
      {bool acknowledge = false}) async {
    if (!available ||
        busy ||
        _disposed ||
        selected.isEmpty ||
        !applicable(proposal, candidate).containsAll(selected) ||
        (selected.contains('lat') != selected.contains('lng')) ||
        (selected.contains('lat') && candidate.approximate && !acknowledge))
      return false;
    bool success = false;
    await _run(() async {
      final row = currentRow(proposal.rowId)!;
      final chosen = selected.toList()..sort();
      final body = <String, dynamic>{
        'candidate_id': candidate.id,
        'expected_version': row.version,
        'fields': chosen,
        'acknowledge_approximate_coordinates': acknowledge
      };
      final pending =
          _applyKeys.putIfAbsent(proposal.id, PendingIdempotencyKey.new);
      try {
        final result = await repository.apply(
            _tenant!,
            batchId,
            proposal.id,
            body,
            pending.keyFor(jsonEncode([_tenant, batchId, proposal.id, body])));
        await _checkTenant();
        if (_disposed) return;
        pending.clear();
        if (result.row.id != row.id ||
            !result.row.isPending ||
            result.row.version < (currentRow(row.id)?.version ?? 0)) {
          final refreshed = await reloadRows();
          await _checkTenant();
          if (_disposed) return;
          replaceRows(refreshed);
          message =
              'La ligne a changé. Données actualisées, relisez avant de continuer.';
          return;
        }
        replaceRows([result.row, ...result.related]);
        final index =
            page?.items.indexWhere((p) => p.id == result.proposal.id) ?? -1;
        if (index >= 0) page!.items[index] = result.proposal;
        _invalidProposals.add(proposal.id);
        success = true;
        message =
            'Proposition appliquée au brouillon. Validation humaine et import restent à effectuer.';
      } on EnrichmentException catch (e) {
        pending.onError(e.status >= 500 ? null : e.code);
        if (e.conflict) {
          _invalidProposals.add(proposal.id);
          // Refresh only. Never replay a conflicting write.
          final refreshed = await reloadRows();
          await _checkTenant();
          if (!_disposed) replaceRows(refreshed);
        }
        rethrow;
      }
    });
    return success;
  }

  @override
  void dispose() {
    _disposed = true;
    _readEpoch++;
    _timer?.cancel();
    super.dispose();
  }
}
