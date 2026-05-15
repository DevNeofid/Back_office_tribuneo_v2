import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/domain/models/sector_model.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

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

  bool isHovered = false;
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
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content:
              Text('Erreur lors de la modification des secteurs d\'activité'),
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCreating = false;
        });
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de l’ajout du secteur d’activité'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kTransparent,
      contentPadding: const EdgeInsets.all(0),
      content: Form(
        key: _formKey,
        child: Stack(children: [
          SizedBox(
            width: SizeConfig.screenWidth * 0.7,
            height: SizeConfig.screenHeight * 0.9,
            child: Container(
              width: SizeConfig.screenWidth * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: kPLGrey2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SelectableText(
                    'Sélectionnez les options qui s\'appliquent:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    height: SizeConfig.screenHeight * 0.5,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: kLBlue,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color.fromARGB(255, 248, 248, 248)
                              .withValues(alpha: 0.8),
                          Colors.white,
                          Colors.white,
                          const Color.fromARGB(255, 248, 248, 248)
                              .withValues(alpha: 0.8),
                        ],
                        stops: const [
                          0.0,
                          0.04,
                          0.96,
                          1.0,
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      controller: ScrollController(
                        initialScrollOffset: 0.0,
                        keepScrollOffset: true,
                      ),
                      child: Column(
                        children: _sectors.map((sector) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedIds.contains(sector.id)) {
                                  _selectedIds.remove(sector.id);
                                } else {
                                  _selectedIds.add(sector.id!);
                                }
                              });
                            },
                            child: MouseRegion(
                              onHover: (event) {
                                setState(() {
                                  isHovered = true;
                                });
                              },
                              cursor: SystemMouseCursors.click,
                              child: CheckboxListTile(
                                activeColor: kLBlue,
                                title: Text(sector.name!),
                                tileColor: isHovered ? kBlue : kBlack,
                                value: _selectedIds.contains(sector.id),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value!) {
                                      _selectedIds.add(sector.id!);
                                    } else {
                                      _selectedIds.remove(sector.id);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newSectorController,
                          decoration: const InputDecoration(
                            labelText: "Nouveau secteur d'activité",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kBlueStart,
                            foregroundColor: kWhite),
                        onPressed: _isCreating ? null : _addNewSector,
                        child: _isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Créer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 38.0),
                  Center(
                    child: _isSaving
                        ? const SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(
                              color: kOrange,
                            ),
                          )
                        : NeoButton(
                            key: UniqueKey(),
                            text: "Enregistrer",
                            onPressed: _submitForm,
                            fontSize: 16,
                            foregroundColor: kPWhite,
                            backgroundColor: kOrange,
                            shadowColor: kBlue,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
