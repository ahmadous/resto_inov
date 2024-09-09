import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminTransactionPage extends StatelessWidget {
  Future<String> _getUserEmail(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc['email']
          .toString()
          .split('@')
          .first; // Truncating the email
    } catch (e) {
      return 'Non spécifié';
    }
  }

  Future<String> _getManagerEmail(String managerId) async {
    try {
      DocumentSnapshot managerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(managerId)
          .get();
      return managerDoc['email']
          .toString()
          .split('@')
          .first; // Truncating the email
    } catch (e) {
      return 'Non spécifié';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Toutes les Transactions'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune transaction trouvée.'));
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              var amount = data['amount'];
              var date = (data['date'] as Timestamp).toDate();
              var formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
              var userId = data['userId'];
              var managerId = data['managerId'] ?? 'Non spécifié';

              return FutureBuilder<String>(
                future: Future.wait([
                  _getUserEmail(userId),
                  _getManagerEmail(managerId),
                ]).then((List<String> emails) {
                  return 'Utilisateur : ${emails[0]}, Gestionnaire : ${emails[1]}';
                }),
                builder: (context, emailSnapshot) {
                  if (emailSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (emailSnapshot.hasError) {
                    return Center(
                        child: Text('Erreur lors du chargement des emails.'));
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    child: ListTile(
                      leading:
                          Icon(Icons.monetization_on, color: Colors.redAccent),
                      title: Text(
                        emailSnapshot.data!,
                        style: GoogleFonts.lato(fontSize: 18),
                      ),
                      subtitle: Text(
                        'Montant : ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(amount)}\nDate : $formattedDate',
                        style: GoogleFonts.lato(
                            fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
