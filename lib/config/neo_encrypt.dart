import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:pointycastle/asymmetric/api.dart';

class NeoEncrypt {
  RSAPublicKey? pubKey;
  RSAPrivateKey? privKey;
  Encrypter? encrypter;
  Signer? signer;

  /// Separator used between the encrypted data and the signature
  final String _separator = ',';

  /// Keys of the json corresponding to a transaction
  final List<String> jsonKeys = [
    "sender_id",
    "receiver_id",
    "sender_fund_id",
    "receiver_fund_id",
    "amount",
    "type",
    "fund_group_id",
    "expiry_date"
  ];

  /// Init function :
  /// Initializes the properties needed for the encryption
  /// to work and for the data to be signed
  /// Reads the public and private RSA key files
  static Future<NeoEncrypt> init() async {
    NeoEncrypt encrypt = NeoEncrypt();
    encrypt.pubKey = RSAKeyParser()
            .parse(await rootBundle.loadString('assets/keys/pub_key.pem'))
        as RSAPublicKey;
    encrypt.privKey = RSAKeyParser()
            .parse(await rootBundle.loadString('assets/keys/priv_key.pem'))
        as RSAPrivateKey;
    encrypt.encrypter = Encrypter(
        RSA(publicKey: encrypt.pubKey!, privateKey: encrypt.privKey!));
    encrypt.signer = Signer(RSASigner(RSASignDigest.SHA256,
        publicKey: encrypt.pubKey, privateKey: encrypt.privKey));
    return encrypt;
  }

  /// Encrypts the data passed in parameter as a string
  Encrypted _encrypt(String text) {
    return encrypter!.encrypt(text);
  }

  /// Decrypts the data and returns it as a string
  String _decrypt(Encrypted e) {
    return encrypter!.decrypt(e);
  }

  /// Signs the encrypted data and returns the signature
  Encrypted _sign(Encrypted e) {
    return signer!.sign(e.base64);
  }

  /// Compares and verifies that the data is signed, returns a boolean
  bool _verify(Encrypted data, Encrypted signature) {
    return signer!.verify(data.base64, signature);
  }

  /// Function specially designed to encrypt the json data allowing a transaction.
  /// Returns a string containing the encrypted data followed by the signature,
  /// separated by the separator defined in the class
  String encryptJson(String data) {
    Map d = json.decode(data);
    Map<String, dynamic> resultMap = {};
    for (int i = 0; i < jsonKeys.length; i++) {
      if (d.containsKey(jsonKeys[i])) {
        resultMap[i.toString()] = d[jsonKeys[i]];
      } else {
        resultMap[i.toString()] = "";
      }
    }
    String result = json.encode(resultMap);
    Encrypted e = _encrypt(result);
    Encrypted s = _sign(e);
    return '${e.base64}$_separator${s.base64}';
  }

  /// Function specifically designed to decrypt the json data enabling a transaction.
  /// Returns a string corresponding to the json data of a transaction.
  /// If json keys were missing they are added with an empty string value
  String decryptJson(String encodedJson) {
    List<String> data = encodedJson.split(_separator);
    Encrypted eData = Encrypted.fromBase64(data[0]);
    Encrypted eSign = Encrypted.fromBase64(data[1]);
    Map<String, dynamic> resultMap = {};
    String result = '';

    if (_verify(eData, eSign)) {
      String badJson = _decrypt(eData);
      Map d = json.decode(badJson);
      for (var i = 0; i < jsonKeys.length; i++) {
        resultMap[jsonKeys[i]] = d[i.toString()];
      }
      result = json.encode(resultMap);
    }
    return result;
  }
}
