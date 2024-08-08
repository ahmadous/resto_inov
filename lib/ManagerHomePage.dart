import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'authservice.dart';

class ManagerHomePage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Accueil'),
        ),
        body: Center(
          child: Text('Aucun utilisateur connecté.'),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Accueil Gestionnaire')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Accueil Gestionnaire')),
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text('Accueil Gestionnaire')),
            body: Center(child: Text('Utilisateur non trouvé')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Accueil Gestionnaire'),
            backgroundColor: Colors.orange,
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  AuthService().signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.qr_code_scanner, size: 30),
                  label: Text('Scanner un QR Code',
                      style: GoogleFonts.lato(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/scan');
                  },
                ),
                SizedBox(height: 20),
                Text('Vos Transactions',
                    style: GoogleFonts.lato(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('managerId', isEqualTo: user!.uid)
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text('Aucune transaction trouvée.'));
                      }
                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          var amount = data['amount'];
                          var date = (data['date'] as Timestamp).toDate();
                          var formattedDate =
                              DateFormat('dd MMM yyyy, HH:mm').format(date);
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 4,
                            child: ListTile(
                              leading: Icon(Icons.monetization_on,
                                  color: Colors.orange),
                              title: Text(
                                  'Montant : ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(amount)}',
                                  style: GoogleFonts.lato(fontSize: 18)),
                              subtitle: Text('Date : $formattedDate',
                                  style: GoogleFonts.lato(
                                      fontSize: 16, color: Colors.grey[600])),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
