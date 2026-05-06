import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> getAvailableBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.map((b) => b.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> authenticate(String reason) async {
    return await _auth.authenticate(
      localizedReason: reason,
      sensitiveTransaction: true,
      persistAcrossBackgrounding: true,
    );
  }
}
