import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminTransactionPage extends StatelessWidget {
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
              var formattedDate =
                  DateFormat('dd MMM yyyy, hh:mm a').format(date);
              var managerId = data['managerId'];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.monetization_on, color: Colors.redAccent),
                  title: Text('Gestionnaire : $managerId',
                      style: GoogleFonts.lato(fontSize: 18)),
                  subtitle: Text(
                      'Montant : ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(amount)}, Date : $formattedDate',
                      style: GoogleFonts.lato(
                          fontSize: 16, color: Colors.grey[600])),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
