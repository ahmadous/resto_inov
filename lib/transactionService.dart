import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final String serverToken =
      '3aee65f1954f34af4f1452ad2de82ad9207fca2c'; // Remplacez par votre vrai token serveur FCM
  final String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  /// Envoie une notification à l'utilisateur via FCM
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
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
          },
          'to': fcmToken,
        }),
      );
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  /// Traite une transaction entre deux utilisateurs
  Future<void> processTransaction(
      String senderId, String receiverId, double amount) async {
    // Firestore transaction pour garantir l'atomicité des opérations
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      // Références des documents des utilisateurs
      DocumentReference senderRef =
          FirebaseFirestore.instance.collection('users').doc(senderId);
      DocumentReference receiverRef =
          FirebaseFirestore.instance.collection('users').doc(receiverId);

      // Récupérer les données des utilisateurs
      DocumentSnapshot senderSnapshot = await transaction.get(senderRef);
      DocumentSnapshot receiverSnapshot = await transaction.get(receiverRef);

      // Vérifier les soldes actuels
      double senderBalance = senderSnapshot['balance'];
      double receiverBalance = receiverSnapshot['balance'];

      if (senderBalance < amount) {
        throw Exception("Solde insuffisant pour l'utilisateur $senderId");
      }

      // Mettre à jour les soldes
      transaction.update(senderRef, {'balance': senderBalance - amount});
      transaction.update(receiverRef, {'balance': receiverBalance + amount});

      // Ajouter les enregistrements de la transaction
      transaction
          .set(FirebaseFirestore.instance.collection('transactions').doc(), {
        'userId': senderId,
        'amount': amount,
        'type': 'sent',
        'date': DateTime.now(),
      });

      transaction
          .set(FirebaseFirestore.instance.collection('transactions').doc(), {
        'userId': receiverId,
        'amount': amount,
        'type': 'received',
        'date': DateTime.now(),
      });
    }).then((_) async {
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
    }).catchError((e) {
      print("Error processing transaction: $e");
    });
  }

  /// Récupère le token FCM d'un utilisateur
  Future<String> getTokenForUser(String userId) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snapshot['fcmToken'];
  }
}
