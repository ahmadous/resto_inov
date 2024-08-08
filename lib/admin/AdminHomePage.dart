import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../authservice.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  double _totalAmount = 0;
  int _transactionCount = 0;
  double _averageAmount = 0;

  @override
  void initState() {
    super.initState();
    _calculateTransactionStats();
  }

  void _calculateTransactionStats() async {
    QuerySnapshot transactionSnapshot =
        await FirebaseFirestore.instance.collection('transactions').get();

    double totalAmount = 0;
    int transactionCount = transactionSnapshot.docs.length;

    for (var doc in transactionSnapshot.docs) {
      double amount = doc['amount'];
      totalAmount += amount;
    }

    setState(() {
      _totalAmount = totalAmount;
      _transactionCount = transactionCount;
      _averageAmount =
          transactionCount > 0 ? totalAmount / transactionCount : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Home'),
        ),
        body: Center(
          child: Text('No user logged in.'),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Admin Home')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Admin Home')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text('Admin Home')),
            body: Center(child: Text('User not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Admin Home'),
            backgroundColor: Colors.redAccent,
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
                Text('Transaction Overview',
                    style: GoogleFonts.lato(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                _buildTransactionAnalysis(),
                SizedBox(height: 20),
                Text('All Transactions',
                    style: GoogleFonts.lato(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
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
                          var managerId = data['managerId'];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 4,
                            child: ListTile(
                              leading: Icon(Icons.monetization_on,
                                  color: Colors.redAccent),
                              title: Text('Manager: $managerId',
                                  style: GoogleFonts.lato(fontSize: 18)),
                              subtitle: Text(
                                  'Amount: ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(amount)}, Date: $formattedDate',
                                  style: GoogleFonts.lato(
                                      fontSize: 16, color: Colors.grey[600])),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Text('All Users',
                    style: GoogleFonts.lato(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No users found.'));
                      }
                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          var email = data['email'];
                          var tickets = data['tickets'] ?? [];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 4,
                            child: ListTile(
                              leading:
                                  Icon(Icons.person, color: Colors.blueAccent),
                              title: Text('User: $email',
                                  style: GoogleFonts.lato(fontSize: 18)),
                              subtitle: Text('Tickets: ${tickets.length}',
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

  Widget _buildTransactionAnalysis() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Total Amount: ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(_totalAmount)}',
                style: GoogleFonts.lato(fontSize: 18)),
            SizedBox(height: 10),
            Text('Total Transactions: $_transactionCount',
                style: GoogleFonts.lato(fontSize: 18)),
            SizedBox(height: 10),
            Text(
                'Average Transaction: ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(_averageAmount)}',
                style: GoogleFonts.lato(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
