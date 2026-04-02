import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'MY_API_KEY', obfuscate: true)
  static final String kAPiKey = _Env.kAPiKey;

  @EnviedField(varName: 'MY_URL', obfuscate: true)
  static final String kUrl = _Env.kUrl;

  @EnviedField(varName: 'MY_NETWORK_NAME', obfuscate: true)
  static final String kNetworkName = _Env.kNetworkName;
}
