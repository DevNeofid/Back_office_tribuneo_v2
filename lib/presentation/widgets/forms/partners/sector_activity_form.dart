import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/domain/models/sector_model.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';

class SectorCreationForm extends StatefulWidget {
  final EntityModel partner;
  const SectorCreationForm({Key? key, required this.partner}) : super(key: key);
  @override
  SectorCreationFormState createState() => SectorCreationFormState();
}

class SectorCreationFormState extends State<SectorCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  final TextEditingController _newSectorController = TextEditingController();
  late List<Sector> _sectors = [];
  late final Set<int> _selectedIds;

  bool _sectorsLoaded = false;
  bool _isSaving = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<int>.from(
      (widget.partner.activitySectors?.map((sector) => sector.id!) ?? [])
          .toList(),
    );
    refreshSector();
  }

  Future<void> refreshSector() async {
    dynamic data = await _partnerUseCase.getSectors();
    if (mounted) {
      setState(() {
        _sectors = data;
        _sectorsLoaded = true;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      Map<String, dynamic> data = {
        'id_entity': widget.partner.id,
        'activitySectors': _selectedIds.map((id) => id.toString()).toList(),
      };

      try {
        await _partnerUseCase.updateSectorPartner(data);
        if (!mounted) return;
        Navigator.of(context).pop(true);

        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Modification des secteurs d\'activité réussie'),
          backgroundColor: kSuccessText,
        ));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content:
              Text('Erreur lors de la modification des secteurs d\'activité'),
          backgroundColor: kDangerText,
        ));
      }
    }
  }

  Future<void> _addNewSector() async {
    String newSectorName = _newSectorController.text.trim();
    if (newSectorName.isNotEmpty) {
      setState(() {
        _isCreating = true;
      });
      try {
        await _partnerUseCase.addNewSector(newSectorName);
        await refreshSector();
        _newSectorController.clear();
        if (!mounted) return;
        setState(() {
          _isCreating = false;
        });
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Le secteur d’activité a été ajouté'),
          backgroundColor: kSuccessText,
        ));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCreating = false;
        });
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de l’ajout du secteur d’activité'),
          backgroundColor: kDangerText,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.partner.name ?? '';

    return Form(
      key: _formKey,
      child: ArcFormPanel(
        eyebrow: "Secteurs d'activité",
        title: name.trim().isEmpty ? "Secteurs d'activité" : name,
        onClose: _isSaving ? null : () => Navigator.pop(context, false),
        actions: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ArcSubmitButton(
            label: 'Enregistrer',
            busy: _isSaving,
            onPressed: _submitForm,
          ),
        ],
        children: [
          ArcFormSection(
            icon: Icons.sell_outlined,
            title: "Secteurs d'activité",
            children: [
              Text("Sélectionnez les options qui s'appliquent.",
                  style: ArcText.body(color: kText2)),
              if (!_sectorsLoaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sector in _sectors)
                      _SectorChip(
                        label: sector.name ?? '',
                        selected: _selectedIds.contains(sector.id),
                        onTap: () {
                          setState(() {
                            if (_selectedIds.contains(sector.id)) {
                              _selectedIds.remove(sector.id);
                            } else {
                              _selectedIds.add(sector.id!);
                            }
                          });
                        },
                      ),
                  ],
                ),
            ],
          ),
          ArcFormSection(
            icon: Icons.add_rounded,
            title: 'Secteur absent de la liste',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newSectorController,
                      decoration: const InputDecoration(
                        labelText: "Nouveau secteur d'activité",
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isCreating ? null : _addNewSector,
                    child: _isCreating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Créer'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pastille de secteur à cocher (maquette FormPartenaire, étape 5).
class _SectorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SectorChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : kNavy700;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? kNavy900 : kSurface,
        shape: StadiumBorder(
          side: BorderSide(
              color: selected ? kNavy900 : kNavy200, width: 1.5),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: ArcText.body(color: fg).copyWith(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}
