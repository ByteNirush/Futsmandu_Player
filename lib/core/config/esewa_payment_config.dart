/// Sandbox URLs and keys for eSewa v2 form integration (see eSewa developer docs).
/// For production, register your merchant URLs and use [ESewaConfig.live] with your
/// `productCode` and secret from the eSewa merchant portal — never ship the EPAYTEST key.
abstract final class EsewaPaymentConfig {
  static const String devSuccessUrl = 'https://developer.esewa.com.np/success';
  static const String devFailureUrl = 'https://developer.esewa.com.np/failure';

  /// EPAYTEST sandbox secret. Override at build time:
  /// `flutter run --dart-define=ESEWA_SECRET_KEY=...`
  static String get secretKey {
    const fromDefine = String.fromEnvironment('ESEWA_SECRET_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return '8gBm/:&EnhH.1/q';
  }
}
