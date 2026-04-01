import 'package:flutter/material.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'package:tribuneo_backoffice/domain/usecases/partner_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/domain/models/sector_model.dart';

class SectorActivityView extends StatefulWidget {
  const SectorActivityView({Key? key}) : super(key: key);
  @override
  SectorActivityViewState createState() => SectorActivityViewState();
}

class SectorActivityViewState extends State<SectorActivityView> {
  final _formKey = GlobalKey<FormState>();
  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  final TextEditingController _newSectorController = TextEditingController();
  late List<Sector> _sectors = [];

  @override
  void initState() {
    refreshSector();
    super.initState();
  }

  Future<void> refreshSector() async {
    dynamic data = await _partnerUseCase.getSectors();
    setState(() {
      _sectors = data;
    });
  }

  Future<void> _addNewSector() async {
    String newSectorName = _newSectorController.text.trim();
    if (newSectorName.isNotEmpty) {
      try {
        await _partnerUseCase.addNewSector(newSectorName);
        await refreshSector();
        _newSectorController.clear();

        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Le secteur d’activité a ajouté '),
          backgroundColor: Colors.green, // Optional: to change background color
        ));
      } catch (e) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de l’ajout du secteur d’activité'),
          backgroundColor: Colors.red, // Optional: to change background color
        ));
      }
    }
  }

  Future<void> _deleteSector(int id) async {
    if (await _showComfirmDialog()) {
      try {
        await _partnerUseCase.deleteSector(id);
        await refreshSector();
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Le secteur d’activité a été supprimé avec succès'),
          backgroundColor: Colors.green, // Optional: to change background color
        ));
      } catch (e) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la suppression du secteur d’activité'),
          backgroundColor: Colors.red, // Optional: to change background color
        ));
      }
    }
  }

  Future<bool> _showComfirmDialog() async {
    bool? confirm = false;

    confirm = await showDialog<bool>(
      context: navigatorKey.currentState!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              "Attention, il est possible que le secteur d'activité soit associé à des partenaires. Voulez-vous vraiment le supprimer ?"),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                    color: kRed, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                'Confirmer',
                style: TextStyle(
                    color: kBlue, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () {
                confirm = true;
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    return confirm!;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          SizedBox(
            width: SizeConfig.screenWidth * 0.9,
            height: SizeConfig.screenHeight * 0.80,
            child: Container(
              width: SizeConfig.screenWidth * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: kPLGrey2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: SizeConfig.screenHeight * 0.62,
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
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: _sectors.map((sector) {
                            return Column(
                              children: [
                                ListTile(
                                  title: SelectableText(sector.name!),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          _deleteSector(sector.id!);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.screenHeight * 0.01),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 5.0, right: 40.0),
                            child: TextField(
                              controller: _newSectorController,
                              decoration: const InputDecoration(
                                labelText: "Nouveau secteur d'activité",
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all<Color>(kOrange),
                          ),
                          onPressed: _addNewSector,
                          child: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ),
                  //const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
