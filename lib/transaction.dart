import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Transactions'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No transactions found.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              var amount = data['amount'];
              var date = (data['date'] as Timestamp).toDate();
              var formattedDate =
                  DateFormat('dd MMM yyyy, hh:mm a').format(date);
              var type = data['type'];

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: ListTile(
                  leading: Icon(
                    type == 'sent' ? Icons.send : Icons.call_received_outlined,
                    color: type == 'sent' ? Colors.red : Colors.green,
                  ),
                  title: Text(
                    'Amount: FCFA $amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Date: $formattedDate\nType: $type',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
