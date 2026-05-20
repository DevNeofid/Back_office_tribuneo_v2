import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

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
          backgroundColor: Colors.red,
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
    SizeConfig().init(context);

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        width: SizeConfig.screenWidth * 0.3,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: kPLGrey2,
        ),
        child: _foundPartner != null
            ? _buildFoundPartnerView()
            : _buildInputView(),
      ),
    );
  }

  Widget _buildInputView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: SelectableText(
                "Rechercher un SIRET",
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w600,
                    color: kOrange),
              ),
            ),
            const SizedBox(height: 30),
            NeoInput(
              controller: siretController,
              hintText: 'Entrer le SIRET',
              keyboardType: TextInputType.number,
              fillColor: kPWhite,
              maxLength: 14,
              formatter: FilteringTextInputFormatter.digitsOnly,
              validator: (value) {
                return FormValidator.validateSiret(value ?? '');
              },
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.poppins(
                      color: _isLoading ? Colors.grey : kRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(right: 40.0),
                        child: CircularProgressIndicator(
                          color: kOrange,
                        ),
                      )
                    : NeoButton(
                        text: "Suivant",
                        onPressed: _checkSiret,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoundPartnerView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SelectableText(
              "Partenaire existant",
              style: GoogleFonts.poppins(
                  fontSize: 28,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                  color: kOrange),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Un partenaire existe déjà avec ce numéro de SIRET, voulez-vous vous en servir ?',
            style: GoogleFonts.poppins(fontSize: 16, color: kBlack),
          ),
          const SizedBox(height: 20),
          Text('Nom : ${_foundPartner!.name ?? 'Non renseigné'}',
              style: GoogleFonts.poppins(fontSize: 14, color: kBlack)),
          Text('Email : ${_foundPartner!.email ?? 'Non renseigné'}',
              style: GoogleFonts.poppins(fontSize: 14, color: kBlack)),
          Text('Téléphone : ${_foundPartner!.phone ?? 'Non renseigné'}',
              style: GoogleFonts.poppins(fontSize: 14, color: kBlack)),
          Text('SIRET : ${_foundPartner!.siret ?? 'Non renseigné'}',
              style: GoogleFonts.poppins(fontSize: 14, color: kBlack)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onPartnerRejected();
                },
                child: Text(
                  'Non',
                  style: GoogleFonts.poppins(
                    color: kRed,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              NeoButton(
                text: "Oui",
                onPressed: () {
                  Navigator.pop(context);
                  widget.onPartnerAccepted(_foundPartner!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
