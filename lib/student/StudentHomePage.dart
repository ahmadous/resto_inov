import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';  // Import de la bibliothèque QR

import '../authservice.dart';
import '../transactionservice.dart';

class StudentHomePage extends StatefulWidget {
  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TransactionService _transactionService = TransactionService();
  bool _isQrVisible = false;

  Future<void> _refreshPage() async {
    setState(() {});
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil Étudiant'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshPage,
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Utilisateur non trouvé'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          double balance = userData['balance'] ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceCard(balance),
                SizedBox(height: 20),
                _buildQrToggleButton(),
                if (_isQrVisible) _buildQrCodeWidget(user!.uid),
                SizedBox(height: 20),
                _buildTransactionSection(context, user),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showStudentTransactions(context);
        },
        backgroundColor: Colors.teal,
        child: Icon(Icons.receipt),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Votre Solde',
              style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(balance)}',
              style: GoogleFonts.lato(fontSize: 36, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrToggleButton() {
    return ElevatedButton.icon(
      icon: Icon(_isQrVisible ? Icons.visibility_off : Icons.visibility, size: 30),
      label: Text(_isQrVisible ? 'Cacher Mon QR Code' : 'Afficher Mon QR Code',
          style: GoogleFonts.lato(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15),
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () {
        setState(() {
          _isQrVisible = !_isQrVisible;
        });
      },
    );
  }

  Widget _buildQrCodeWidget(String uid) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal, width: 4),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              'Voici votre QR Code',
              style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            QrImageView(  // Utilisation de QrImageView pour générer le QR code
              data: uid,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSection(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos Transactions',
          style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .where('userId', isEqualTo: user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('Aucune transaction trouvée.'));
            }

            List<QueryDocumentSnapshot> credits = snapshot.data!.docs
                .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'received')
                .toList();

            List<QueryDocumentSnapshot> debits = snapshot.data!.docs
                .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'sent')
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTransactionList(context, 'Crédits', credits, Colors.green),
                _buildTransactionList(context, 'Débits', debits, Colors.red),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionList(BuildContext context, String title, List<QueryDocumentSnapshot> transactions, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        SizedBox(height: 10),
        ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: transactions.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var amount = data['amount'];
            var date = (data['date'] as Timestamp).toDate();
            var formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.monetization_on, color: color),
                title: Text(
                  'Montant : ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(amount)}',
                  style: GoogleFonts.lato(fontSize: 18),
                ),
                subtitle: Text(
                  'Date : $formattedDate',
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  void _showStudentTransactions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vos Crédits Reçus',
                style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('userId', isEqualTo: user!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur : ${snapshot.error}'));
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
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                          child: ListTile(
                            leading: Icon(Icons.monetization_on, color: Colors.green),
                            title: Text(
                              'Montant : ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ', decimalDigits: 0).format(amount)}',
                              style: GoogleFonts.lato(fontSize: 18),
                            ),
                            subtitle: Text(
                              'Date : $formattedDate',
                              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
