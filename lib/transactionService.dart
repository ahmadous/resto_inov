import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final String serverToken = '3aee65f1954f34af4f1452ad2de82ad9207fca2c';
  final String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  Future<void> sendNotification(
      String title, String body, String fcmToken) async {
    try {
      await http.post(
        Uri.parse(fcmUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverToken',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{'body': body, 'title': title},
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK'
          },
          'to': fcmToken,
        }),
      );
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<void> processTransaction(
      String senderId, String receiverId, double amount) async {
    // Mise à jour des balances dans Firestore
    await FirebaseFirestore.instance.collection('users').doc(senderId).update({
      'balance': FieldValue.increment(-amount),
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .update({
      'balance': FieldValue.increment(amount),
    });

    // Stocker la transaction dans Firestore
    await FirebaseFirestore.instance.collection('transactions').add({
      'userId': senderId,
      'amount': amount,
      'type': 'sent',
      'date': DateTime.now(),
    });

    await FirebaseFirestore.instance.collection('transactions').add({
      'userId': receiverId,
      'amount': amount,
      'type': 'received',
      'date': DateTime.now(),
    });

    // Récupérer les tokens FCM des utilisateurs
    String senderToken = await getTokenForUser(senderId);
    String receiverToken = await getTokenForUser(receiverId);

    // Envoyer des notifications aux utilisateurs
    await sendNotification(
      "Transaction envoyée",
      "Vous avez envoyé $amount FCFA",
      senderToken,
    );

    await sendNotification(
      "Transaction reçue",
      "Vous avez reçu $amount FCFA",
      receiverToken,
    );
  }

  Future<String> getTokenForUser(String userId) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snapshot['fcmToken'];
  }
}
