// Conditional export: native implementation on mobile/desktop, stub on web.
export 'biometric_service_stub.dart'
    if (dart.library.io) 'biometric_service_native.dart';
