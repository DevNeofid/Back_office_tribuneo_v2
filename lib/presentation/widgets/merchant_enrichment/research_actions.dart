import 'package:flutter/material.dart';
import '../../../domain/models/assistant_model.dart';

/// Available only inside a dedicated comparison controller's widget scope.
class ResearchActions extends InheritedWidget {
  final Future<void> Function(AssistantEnrichmentResearchBlock) open;
  const ResearchActions({super.key, required this.open, required super.child});
  static ResearchActions? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ResearchActions>();
  @override
  bool updateShouldNotify(ResearchActions oldWidget) => open != oldWidget.open;
}
