import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/domain/models/sector_model.dart';

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
  bool _isLoading = false;

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
      setState(() => _isLoading = true);
      try {
        await _partnerUseCase.addNewSector(newSectorName);
        await refreshSector();
        _newSectorController.clear();

        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Le secteur d’activité a été ajouté"),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Erreur lors de l’ajout du secteur d’activité"),
          backgroundColor: Colors.red,
        ));
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la suppression du secteur d’activité'),
          backgroundColor: Colors.red,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          title: Text(
            "Attention, il est possible que ce secteur d'activité soit associé à des partenaires. Voulez-vous vraiment le supprimer ?",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Annuler',
                style: GoogleFonts.poppins(
                    color: kRed, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Confirmer',
                style: GoogleFonts.poppins(
                    color: kBlue, fontWeight: FontWeight.bold, fontSize: 15),
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
    SizeConfig().init(context);
    final bool isCompact = MediaQuery.of(context).size.width < 1000;

    return Form(
      key: _formKey,
      child: SizedBox(
        height: SizeConfig.screenHeight * 0.9,
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              const SizedBox(height: 50),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 600 : 800),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newSectorController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kWhite,
                          labelText: "Nouveau secteur d'activité",
                          labelStyle: GoogleFonts.poppins(color: kBlue),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: kBlue, width: 2),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    SizedBox(
                      height: 52,
                      child: _isLoading
                          ? const AspectRatio(
                              aspectRatio: 1,
                              child: Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: kOrange),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              onPressed: _addNewSector,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                'Ajouter',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 600 : 800),
                child: Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: kBlue,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nom du secteur',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kWhite,
                                ),
                              ),
                              Text(
                                'Actions',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._sectors.asMap().entries.map((entry) {
                          final index = entry.key;
                          final sector = entry.value;
                          final isEvenRow = index % 2 == 0;

                          return Container(
                            color: isEvenRow
                                ? kWhite
                                : kLBlue.withValues(alpha: 0.10),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    sector.name ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: kBlueEnd,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  tooltip: 'Supprimer',
                                  onPressed: () {
                                    _deleteSector(sector.id!);
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
