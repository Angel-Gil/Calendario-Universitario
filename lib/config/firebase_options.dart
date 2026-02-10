/// Configuración de Firebase (generada manualmente)
/// Para configurar correctamente:
/// 1. Ve a Firebase Console > Configuración del proyecto > Tus apps > Android
/// 2. Descarga google-services.json y colócalo en android/app/
/// 3. O ejecuta: flutterfire configure
class DefaultFirebaseOptions {
  static const String apiKey = 'TU_API_KEY_AQUI';
  static const String appId = '1:116719323205907406003:android:XXXXXXXX';
  static const String messagingSenderId = '116719323205907406003';
  static const String projectId = 'calendario-a0750';
  static const String storageBucket = 'calendario-a0750.appspot.com';

  /// Verifica si Firebase está configurado correctamente
  static bool get isConfigured => apiKey != 'TU_API_KEY_AQUI';
}
