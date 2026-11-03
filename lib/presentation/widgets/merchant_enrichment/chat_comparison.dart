import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/assistant_model.dart';
import '../../../domain/usecases/merchant_enrichment/chat_comparison_usecase.dart';
import '../assistant/assistant_controller.dart';
import '../assistant/assistant_panel.dart';

/// Dedicated controller and session: the ordinary assistant is never reset or replaced.
class ChatComparison extends StatefulWidget {
  final ChatComparisonUseCase session;
  const ChatComparison({super.key, required this.session});
  @override
  State<ChatComparison> createState() => _ChatComparisonState();
}

class _ChatComparisonState extends State<ChatComparison> {
  late final AssistantController controller;
  final input = TextEditingController();
  Timer? timer;
  bool reviewing = false, checking = false;
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
    if (!controller.isOpen) Navigator.pop(context);
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
        Navigator.pop(context, selected);
    } catch (_) {
      if (mounted) controller.invalidateContext();
    } finally {
      reviewing = false;
    }
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

  @override
  Widget build(BuildContext context) => Dialog(
      child: SizedBox(
          width: 720,
          height: 690,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                    'Comparaison Néo · Lot ${widget.session.reference.batchId} · Ligne ${widget.session.reference.rowId} · Version ${widget.session.reference.expectedVersion}\n'
                    'Comparer les candidats publics existants. Le choix et l’application restent à confirmer.')),
            Expanded(
                child: ChangeNotifierProvider<AssistantController>.value(
                    value: controller,
                    child: AssistantPanel(input: input, fullScreen: false))),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour au choix manuel')),
          ])));
}
