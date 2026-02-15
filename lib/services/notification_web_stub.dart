// Stub - se usa cuando no se resuelve ni web ni mobile
Future<void> initializeWebNotifications() async {}
Future<void> showWebNotification(String title, String body) async {}
Future<String> getWebNotificationPermission() async => 'denied';
