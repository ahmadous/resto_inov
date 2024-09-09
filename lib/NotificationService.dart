import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  void initialize() {
    // Demander la permission pour les notifications
    _firebaseMessaging.requestPermission();

    // Gérer les notifications en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground message: ${message.notification?.title}');
      // Afficher une alerte ou gérer la notification ici
    });

    // Gérer les notifications lorsque l'application est en arrière-plan ou terminée
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      // Gérer la navigation ou d'autres actions ici
    });
  }

  // Obtenir le token FCM de l'appareil
  Future<String?> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
    return token;
  }
}
