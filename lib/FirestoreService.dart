import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ajouter un ticket pour un étudiant
  Future<void> addTicket(String userId, Map<String, dynamic> ticketData) async {
    try {
      await _db.collection('users').doc(userId).update({
        'tickets': FieldValue.arrayUnion([ticketData])
      });

      // Enregistrer la transaction
      await _db.collection('transactions').add({
        'userId': userId,
        'type': 'purchase',
        'amount': ticketData['amount'],
        'date': DateTime.now(),
      });
    } catch (e) {
      print('Erreur lors de l\'ajout du ticket: $e');
    }
  }

  // Déduire un ticket en fonction de l'heure
  Future<void> useTicket(String userId, String ticketId) async {
    try {
      DocumentSnapshot userDoc =
          await _db.collection('users').doc(userId).get();

      if (userDoc.exists) {
        List tickets = userDoc['tickets'] ?? [];

        if (tickets.isNotEmpty) {
          // Logique pour déduire le montant selon l'heure
          DateTime now = DateTime.now();
          double amount = (now.hour >= 4 && now.hour <= 10) ? 50 : 100;

          // Retirer le ticket utilisé
          tickets.removeWhere((ticket) => ticket['id'] == ticketId);

          // Mise à jour des tickets restants
          await _db
              .collection('users')
              .doc(userId)
              .update({'tickets': tickets});

          // Enregistrer la transaction
          await _db.collection('transactions').add({
            'userId': userId,
            'type': 'use',
            'amount': amount,
            'date': now,
          });
        } else {
          print('Aucun ticket trouvé pour cet utilisateur.');
        }
      } else {
        print('Document utilisateur non trouvé.');
      }
    } catch (e) {
      print('Erreur lors de l\'utilisation du ticket: $e');
    }
  }

  // Voir toutes les transactions (pour l'admin)
  Stream<List<Map<String, dynamic>>> getAllTransactions() {
    return _db.collection('transactions').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  // Recevoir des notifications (ajouter une fonctionnalité de push notification Firebase)
  // Cela nécessite l'intégration de Firebase Cloud Messaging (FCM)
}
