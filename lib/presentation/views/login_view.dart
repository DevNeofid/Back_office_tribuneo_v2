import 'package:back_office_tribuneo_v2/presentation/views/_base_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/domain/errors/rate_limit_exception.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/login_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_model.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/network_repository.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.title});

  final String title;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends BaseStatefulWidget<LoginView> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final StorageFunction storageFunction = StorageFunction();

  final LoginUsecase loginUsecase = LoginUsecase();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showPassword = true;
  bool _isLoading = false;

  void _redirect({String routeName = '/'}) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }

  bool isNetworkAdmin(UserModel user) => user.isNetworkAdmin;

  Future<void> rejectNonAdminShopAccess() async {
    await storageFunction.clearUser();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    final messenger = snackbarKey.currentState ?? ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Accès refusé : votre compte n\'est pas un compte administrateur.',
        ),
        backgroundColor: Colors.red.shade300,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void onDataReceived(dynamic data) {}

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserModel shopUser = await loginUsecase.login(
          usernameController.text,
          passwordController.text,
        );

        TextInput.finishAutofillContext();

        if (!isNetworkAdmin(shopUser)) {
          await rejectNonAdminShopAccess();
          return;
        }

        try {
          final networkRepository = NetworkRepository();
          final allNetworks = await networkRepository.getNetworks();

          final storageService = StorageService();
          final String? idNetworkStr =
              await storageService.readSecureData('user_id_network');
          final int? userNetworkId =
              idNetworkStr != null ? int.tryParse(idNetworkStr) : null;

          if (userNetworkId != null) {
            final singleNetwork =
                allNetworks.where((n) => n.id == userNetworkId).toList();

            if (singleNetwork.isNotEmpty) {
              await storageFunction.saveNetwork(
                singleNetwork.first.toJson(),
              );
              globalNetworkName = singleNetwork.first.name;
            }
          }
        } catch (e) {}

        if (mounted) {
          _redirect();
        }
      } on RateLimitException catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        snackbarKey.currentState?.hideCurrentSnackBar();
        snackbarKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: Colors.red.shade300,
            duration: const Duration(seconds: 8),
          ),
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        snackbarKey.currentState?.hideCurrentSnackBar();
        snackbarKey.currentState?.showSnackBar(
          SnackBar(
            content: const Text(
                "Erreur de connexion. Veuillez vérifier vos identifiants."),
            backgroundColor: Colors.red.shade300,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kWhite,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kOrange),
              ),
            )
          : Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        margin: const EdgeInsets.only(top: 150, bottom: 20),
                        height: screenSize.height * 0.20,
                        width: screenSize.width,
                        decoration: const BoxDecoration(
                          color: kWhite,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 70,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Center(
                                    child: SvgPicture.asset(
                                      'assets/svg/logo_tribuneo.svg',
                                      fit: BoxFit.contain,
                                      alignment: Alignment.topCenter,
                                      width: 280,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Text(
                              "Backoffice",
                              style: GoogleFonts.poppins(
                                  fontSize: 34,
                                  letterSpacing: 0.3,
                                  fontWeight: FontWeight.w500,
                                  color: kGrey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: 400,
                        child: AutofillGroup(
                          child: Column(
                            children: [
                              TextFormField(
                                autofillHints: const [AutofillHints.username],
                                controller: usernameController,
                                decoration: const InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(width: 2, color: kBlue),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  labelText: "Nom d'utilisateur",
                                  labelStyle: TextStyle(
                                    color: kBlue,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: kBlue,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Entrez un identifiant valide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                autofillHints: const [AutofillHints.password],
                                controller: passwordController,
                                obscureText: _showPassword,
                                decoration: InputDecoration(
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(width: 2, color: kBlue),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  labelText: "Mot de passe",
                                  labelStyle: const TextStyle(
                                    color: kBlue,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: kBlue,
                                  ),
                                  suffixIcon: IconButton(
                                    hoverColor: kLBlue,
                                    splashRadius: 16,
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: kBlue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                height: 50,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    NeoButton(
                                      key: UniqueKey(),
                                      text: "Connexion",
                                      onPressed: login,
                                      fontSize: 16,
                                      foregroundColor: kPWhite,
                                      backgroundColor: kOrange,
                                      shadowColor: kBlue,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
