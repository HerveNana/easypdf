// Web stub — biometric authentication is not supported in browsers.

class BiometricService {
  static Future<bool> canAuthenticate() async => false;
  static Future<bool> isDeviceSupported() async => false;
  static Future<List<String>> getAvailableBiometrics() async => [];
  static Future<bool> authenticate(String reason) async => false;
}
