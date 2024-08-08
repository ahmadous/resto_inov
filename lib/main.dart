import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:resto_inov/NotificationService.dart';
import 'admin/AdminHomePage.dart';
import 'MainPage.dart';
import 'LoginPage.dart';
import 'ManagerHomePage.dart';
import 'SignUpPage.dart';
import 'StudentHomePage.dart';
import 'Wrapper.dart';
import 'admin/MainAdminPage.dart';
import 'authservice.dart';
import 'transaction.dart';
import 'MyQrCodePage.dart';
import 'QrScannerPage.dart';
import 'SettingsPage.dart'; // Importez la page des paramètres

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Initialiser le service de notifications
  NotificationService().initialize();

  runApp(MyApp());
}

// Gestion des messages en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: AuthService().user,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'University Ticket System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Wrapper(),
          '/login': (context) => LoginPage(),
          '/signup': (context) => SignUpPage(),
          '/student_home': (context) => StudentHomePage(),
          '/manager_home': (context) => ManagerHomePage(),
          '/admin_home': (context) => AdminHomePage(),
          '/transactions': (context) => TransactionsPage(),
          '/my_qr': (context) => MyQrCodePage(),
          '/home': (context) => ManagerHomePage(),
          '/scan': (context) => QrScannerPage(),
          '/settings': (context) => SettingsPage(),
          '/main': (context) => MainPage(),
          '/admin_home': (context) =>
              MainAdminPage(), // Page Admin avec le BottomNavigationBar
        },
      ),
    );
  }
}
