import 'ui/enrichment_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/assistant_model.dart';
import '../../../domain/models/merchant_enrichment/enrichment_models.dart';
import '../../utils/common.dart';
import '../../../domain/usecases/merchant_enrichment/chat_comparison_usecase.dart';
import '../assistant/assistant_controller.dart';
import '../assistant/assistant_panel.dart';
import 'research_actions.dart';
import 'research_form.dart';
import '../../../domain/usecases/merchant_enrichment/research_usecase.dart';

typedef ChatComparisonSelection = ({
  EnrichmentProposal proposal,
  EnrichmentCandidate candidate
});

/// Fin d'une comparaison affichée dans le bouton flottant de Néo.
class ChatComparisonOutcome {
  /// Candidat choisi dans la conversation, à relire avant application.
  final ChatComparisonSelection? selection;

  /// Rouvrir « Compléter les informations » (retour au choix manuel, candidat
  /// choisi, recherche précisée).
  final bool reopenPanel;

  const ChatComparisonOutcome._(this.selection, this.reopenPanel);

  /// Panneau fermé ou réduit : on ne rouvre rien.
  static const ChatComparisonOutcome closed =
      ChatComparisonOutcome._(null, false);
  static const ChatComparisonOutcome manual =
      ChatComparisonOutcome._(null, true);
  const ChatComparisonOutcome.selected(ChatComparisonSelection selection)
      : this._(selection, true);
}

/// Dedicated controller and session: the ordinary assistant is never reset or replaced.
///
/// Sans [onDone] : affichage en dialogue, fermé par `Navigator.pop` avec le
/// candidat choisi. Avec [onDone] : panneau du bouton flottant de Néo
/// (`AssistantDockedPanel`), qui reçoit l'issue de la comparaison.
class ChatComparison extends StatefulWidget {
  final ChatComparisonUseCase session;
  final ValueChanged<ChatComparisonOutcome>? onDone;

  /// Panneau du bouton flottant en plein écran (mobile).
  final bool fullScreen;
  const ChatComparison(
      {super.key, required this.session, this.onDone, this.fullScreen = false});
  @override
  State<ChatComparison> createState() => _ChatComparisonState();
}

class _ChatComparisonState extends State<ChatComparison> {
  late final AssistantController controller;
  final input = TextEditingController();
  Timer? timer;
  bool reviewing = false, checking = false, done = false;

  bool get docked => widget.onDone != null;

  void finish(ChatComparisonOutcome outcome) {
    if (done || !mounted) return;
    done = true;
    if (docked) {
      widget.onDone!(outcome);
    } else {
      Navigator.pop(context, outcome.selection);
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AssistantController(repository: widget.session)
      ..onReviewCandidate = review;
    controller.addListener(changed);
    widget.session.enrichment.addListener(validateLocal);
    widget.session.lifetime?.addListener(validateLocal);
    timer = Timer.periodic(const Duration(seconds: 1), (_) => validate());
    controller.open();
    controller.send(
        'Compare les candidats déjà sourcés pour cette ligne. Explique les différences et les incertitudes avant mon choix humain.');
  }

  void changed() {
    if (!mounted) return;
    if (!controller.isOpen) finish(ChatComparisonOutcome.closed);
  }

  void validateLocal() {
    if (!widget.session.locallyValid) {
      // The scope is already invalid synchronously. Publish UI changes after
      // the owning button has finished unmounting (the widget tree is locked).
      scheduleMicrotask(() {
        if (mounted) controller.invalidateContext();
      });
    }
  }

  Future<void> validate() async {
    if (checking || controller.contextInvalid) return;
    checking = true;
    try {
      await widget.session.check();
    } catch (_) {
      if (mounted) controller.invalidateContext();
    } finally {
      checking = false;
    }
  }

  Future<void> review(
      AssistantEnrichmentCandidatesBlock block, String id) async {
    if (reviewing || controller.contextInvalid) return;
    reviewing = true;
    try {
      final selected = await widget.session.review(block, id);
      if (mounted && !controller.contextInvalid)
        finish(ChatComparisonOutcome.selected(selected));
    } catch (_) {
      if (mounted) controller.invalidateContext();
    } finally {
      reviewing = false;
    }
  }

  Future<void> research(AssistantEnrichmentResearchBlock block) async {
    if (reviewing || controller.contextInvalid) return;
    reviewing = true;
    try {
      await widget.session.prepareResearch(block);
      if (!mounted || controller.contextInvalid) return;
      final form = ResearchUseCase(widget.session.enrichment, widget.session.proposal,
        () => mounted && !controller.contextInvalid && widget.session.locallyValid);
      final accepted = await showDialog<bool>(context: context,
        builder: (_) => ResearchForm(session: form));
      // A subsequent comparison is opened by a new human action and gets a new session.
      if (accepted == true && mounted) finish(ChatComparisonOutcome.manual);
    } catch (_) {
      if (mounted) controller.invalidateContext();
    } finally { reviewing = false; }
  }

  @override
  void dispose() {
    timer?.cancel();
    widget.session.enrichment.removeListener(validateLocal);
    widget.session.lifetime?.removeListener(validateLocal);
    controller.removeListener(changed);
    controller.dispose();
    input.dispose();
    super.dispose();
  }

  String get _contextText {
    final row = widget.session.enrichment.currentRow(widget.session.reference.rowId);
    return '${row?.textOf('name') ?? ''}\n'
        'Comparaison Néo · Lot ${widget.session.reference.batchId} · Ligne ${row?.position ?? widget.session.reference.rowId}\n'
        'Comparer les candidats publics existants. Le choix et l’application restent à confirmer.';
  }

  Widget _panel({required bool fullScreen, Widget? banner}) =>
      ChangeNotifierProvider<AssistantController>.value(
          value: controller,
          child: ResearchActions(
              open: research,
              child: AssistantPanel(
                  input: input,
                  fullScreen: fullScreen,
                  title: docked ? 'Néo · Comparaison' : 'Néo',
                  banner: banner)));

  @override
  Widget build(BuildContext context) {
    if (docked) {
      return _panel(
          fullScreen: widget.fullScreen,
          banner: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .22),
              color: kSurface2,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                  decoration: BoxDecoration(
                      color: kNavy100,
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 2),
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_contextText,
                            style: const TextStyle(
                                fontSize: 12, height: 1.45, color: kNavy700)),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                                style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: EdgeInsets.zero,
                                    textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                onPressed: () =>
                                    finish(ChatComparisonOutcome.manual),
                                child: const Text('Retour au choix manuel'))),
                      ])))));
    }
    return EnrichmentDialog(
        maxWidth: 900,
        scrollable: false,
        title: const Text('Comparaison Néo'),
        onClose: () => Navigator.pop(context),
        content: Column(children: [
          ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .22),
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: kNavy100, borderRadius: BorderRadius.circular(14)),
                child: SingleChildScrollView(
                    child: Text(_contextText,
                        style: const TextStyle(
                            fontSize: 12, height: 1.45, color: kNavy700))),
              )),
          Expanded(child: _panel(fullScreen: false)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour au choix manuel'))
        ],
      );
  }
}
