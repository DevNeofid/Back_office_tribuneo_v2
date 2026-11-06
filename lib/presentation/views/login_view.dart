import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import 'package:back_office_tribuneo_v2/presentation/views/_base_view.dart';
import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/domain/errors/rate_limit_exception.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/login_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_model.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
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

  /// Échec de la dernière tentative, affiché au-dessus des champs.
  String? _errorMessage;

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

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

    _showError(
        'Accès refusé : votre compte n\'est pas un compte administrateur.');
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void onDataReceived(dynamic data) {}

  Future<void> login() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
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

        _showError(e.userMessage);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        _showError("Erreur de connexion. Veuillez vérifier vos identifiants.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCanvas,
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(flex: 52, child: _BrandPanel()),
              Expanded(
                flex: 48,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 48),
                    child: _buildForm(),
                  ),
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 300, child: _BrandPanel(compact: true)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Center(child: _buildForm()),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: ArcText.body(color: kNavy700)
                .copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
      );

  Widget _buildForm() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Connexion',
                  style: ArcText.display().copyWith(fontSize: 36, height: 1.1)),
              const SizedBox(height: 6),
              Text('Réservée aux comptes administrateurs.',
                  style: ArcText.body(color: kText2)),
              const SizedBox(height: 22),
              if (_errorMessage != null) ...[
                _ErrorBanner(_errorMessage!),
                const SizedBox(height: 22),
              ],
              _fieldLabel("Nom d'utilisateur"),
              Semantics(
                label: "Nom d'utilisateur",
                child: TextFormField(
                  autofillHints: const [AutofillHints.username],
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  style: ArcText.body().copyWith(fontSize: 15),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrez un identifiant valide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 22),
              _fieldLabel('Mot de passe'),
              Semantics(
                label: 'Mot de passe',
                child: TextFormField(
                  autofillHints: const [AutofillHints.password],
                  controller: passwordController,
                  obscureText: _showPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => login(),
                  style: ArcText.body().copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      tooltip: _showPassword
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                      color: kNavy600,
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _isLoading ? null : login,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  textStyle: ArcText.body()
                      .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: TribuneoLoader(),
                      )
                    : const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panneau navy de gauche : logo, accroche et motif des arcs.
class _BrandPanel extends StatelessWidget {
  final bool compact;
  const _BrandPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: kNavy900),
      child: Stack(children: [
        Positioned(
          right: compact ? -60 : -90,
          bottom: compact ? -40 : 120,
          child: Opacity(
            opacity: compact ? 0.22 : 1,
            child: ArcPicto(
                width: compact ? 300 : 560, ink: kNavy700, accent: kOrange),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? 32 : 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ArcWordmark(height: 40),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('BACKOFFICE',
                        style: ArcText.dataSmall(color: kNavy400)
                            .copyWith(letterSpacing: 1.3)),
                    const SizedBox(height: 12),
                    Text("L'espace de gestion du réseau Tribuneo",
                        style: ArcText.display(color: Colors.white)
                            .copyWith(fontSize: compact ? 34 : 52, height: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Alerte d'échec de connexion (fond framboise clair).
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kDangerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffF7B9CB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.error_outline_rounded,
                  size: 18, color: kDangerText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style:
                      ArcText.body(color: kDangerText).copyWith(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
