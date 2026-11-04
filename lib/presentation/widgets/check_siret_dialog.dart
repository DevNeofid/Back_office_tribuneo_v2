import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';

class CheckSiretDialog extends StatefulWidget {
  final Function(EntityModel partner) onPartnerAccepted;
  final Function(String siret) onPartnerNotFound;
  final Function() onPartnerRejected;

  const CheckSiretDialog({
    super.key,
    required this.onPartnerAccepted,
    required this.onPartnerNotFound,
    required this.onPartnerRejected,
  });

  @override
  State<CheckSiretDialog> createState() => _CheckSiretDialogState();
}

class _CheckSiretDialogState extends State<CheckSiretDialog> {
  final TextEditingController siretController = TextEditingController();
  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  EntityModel? _foundPartner;

  Future<void> _checkSiret() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      EntityModel? partner =
          await _partnerUseCase.getPartnerBySiret(siretController.text);
      if (!mounted) return;

      if (partner != null) {
        setState(() {
          _foundPartner = partner;
          _isLoading = false;
        });
      } else {
        Navigator.pop(context);
        widget.onPartnerNotFound(siretController.text);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la recherche : $error',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: kDangerText,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    siretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _foundPartner != null
        ? _buildFoundPartnerView()
        : _buildInputView();
  }

  Widget _buildInputView() {
    return ArcDialog(
      icon: Icons.search_rounded,
      title: 'Rechercher un SIRET',
      maxWidth: 500,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
                "Avant de créer une fiche, on vérifie qu'elle n'existe pas déjà."),
            const SizedBox(height: 18),
            ArcMonoField(
              child: NeoInput(
                controller: siretController,
                hintText: 'Entrer le SIRET',
                keyboardType: TextInputType.number,
                fillColor: kSurface,
                maxLength: 14,
                formatter: FilteringTextInputFormatter.digitsOnly,
                validator: (value) {
                  return FormValidator.validateSiret(value ?? '');
                },
              ),
            ),
            const SizedBox(height: 6),
            Text('14 chiffres, sans espace.',
                style: ArcText.small(color: kText3)),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ArcSubmitButton(
          label: 'Suivant',
          busy: _isLoading,
          onPressed: _checkSiret,
        ),
      ],
    );
  }

  Widget _buildFoundPartnerView() {
    final EntityModel found = _foundPartner!;
    return ArcDialog(
      icon: Icons.task_outlined,
      tone: ArcTone.warning,
      title: 'Fiche existante',
      maxWidth: 520,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
              "Une fiche utilise déjà ce numéro de SIRET. Souhaitez-vous l'utiliser ?"),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kNavy50,
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArcAvatar(found.name ?? '', size: 44, dark: true),
                const SizedBox(width: 14),
                Expanded(
                  child: ArcDefinitionList(
                    [
                      (
                        'Nom',
                        Text(found.name ?? 'Non renseigné',
                            style: ArcText.body(color: kNavy900).copyWith(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      ('Email', Text(found.email ?? 'Non renseigné')),
                      (
                        'Téléphone',
                        Text(found.phone ?? 'Non renseigné',
                            style: ArcText.data()),
                      ),
                      (
                        'SIRET',
                        Text(found.siret ?? 'Non renseigné',
                            style: ArcText.data()),
                      ),
                    ],
                    labelWidth: 82,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _foundPartner = null;
            });
          },
          child: const Text('Modifier le SIRET'),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onPartnerRejected();
          },
          child: const Text('Non'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onPartnerAccepted(_foundPartner!);
          },
          child: const Text('Oui, utiliser cette fiche'),
        ),
      ],
    );
  }
}
