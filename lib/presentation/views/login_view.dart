import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tribuneo_backoffice/domain/usecases/login_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';

import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/widgets/neo_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.title});

  final String title;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final LoginUsecase loginUsecase = LoginUsecase();
  // late UserModel connectedUser;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showPassword = true;

  void _redirect({String routeName = '/'}) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await loginUsecase.login(
            usernameController.text, passwordController.text);
        _redirect();
      } catch (e) {
        snackbarKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
                "Erreur de connexion. Veuillez vérifier vos identifiants."),
            backgroundColor: Colors.red,
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
      body: Column(
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
                          // initialValue: "Cci04admin",
                          autofillHints: const [AutofillHints.username],
                          controller: usernameController,
                          decoration: const InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(width: 2, color: kBlue),
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
                              borderSide: BorderSide(width: 2, color: kBlue),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
