import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../authservice.dart';

class ManagerHomePage extends StatefulWidget {
  @override
  _ManagerHomePageState createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  TextEditingController _filterController = TextEditingController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void dispose() {
    _filterController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  String truncateEmail(String email) {
    return email.split('@').first;
  }

  void _onRefresh() async {
    setState(() {});
    _refreshController.refreshCompleted();
  }

  Future<List<Map<String, dynamic>>> _getTransactionsWithEmail(List<QueryDocumentSnapshot> transactions) async {
    List<Map<String, dynamic>> transactionList = [];

    for (var transaction in transactions) {
      var data = transaction.data() as Map<String, dynamic>;
      var userId = data['userId'];
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        var userEmail = userDoc['email'] ?? '';
        var truncatedEmail = truncateEmail(userEmail);

        if (truncatedEmail.contains(_filterController.text)) {
          transactionList.add({
            'amount': data['amount'],
            'date': data['date'],
            'userId': userId,
            'userEmail': userEmail,
          });
        }
      }
    }

    return transactionList;
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
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: ListView(
            children: [
              _buildActionSection(context),
              SizedBox(height: 20),
              _buildFilterSection(),
              SizedBox(height: 20),
              _buildTransactionSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Actions Rapides',
              style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.qr_code_scanner, size: 30),
              label: Text('Scanner un QR Code', style: GoogleFonts.lato(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/scan');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Filtrer les Transactions',
              style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _filterController,
              decoration: InputDecoration(
                labelText: 'Rechercher par nom d\'utilisateur',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Rafraîchir l'affichage lors de la saisie
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  .where('managerId', isEqualTo: user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aucune transaction trouvée.'));
                }

                var transactions = snapshot.data!.docs;

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getTransactionsWithEmail(transactions),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (futureSnapshot.hasError) {
                      return Center(child: Text('Erreur lors du filtrage des transactions.'));
                    }

                    var filteredTransactions = futureSnapshot.data ?? [];

                    return ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: filteredTransactions.map((transaction) {
                        var amount = transaction['amount'];
                        var date = (transaction['date'] as Timestamp).toDate();
                        var formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
                        var userEmail = truncateEmail(transaction['userEmail'] ?? '');

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                          child: ListTile(
                            leading: Icon(Icons.monetization_on, color: Colors.orange),
                            title: Text(
                              'Montant : ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(amount)}',
                              style: GoogleFonts.lato(fontSize: 18),
                            ),
                            subtitle: Text(
                              'Date : $formattedDate\nÀ : $userEmail',
                              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
