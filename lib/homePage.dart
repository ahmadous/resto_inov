import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resto_inov/authservice.dart';

class HomePage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

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
            appBar: AppBar(title: Text('Home')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Home')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text('Home')),
            body: Center(child: Text('User data not found')),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        var role = userData['role'];

        return Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            backgroundColor: Colors.teal,
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
          body: role == 'student'
              ? _buildStudentHome(context)
              : role == 'manager'
                  ? _buildManagerHome(context)
                  : _buildAdminHome(context),
        );
      },
    );
  }

  Widget _buildStudentHome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome, Student!',
            style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.qr_code, size: 30),
            label:
                Text('Show My QR Code', style: GoogleFonts.lato(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/my_qr');
            },
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.history, size: 30),
            label: Text('View My Transactions',
                style: GoogleFonts.lato(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/transactions');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagerHome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome, Manager!',
            style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.qr_code_scanner, size: 30),
            label: Text('Scan QR Code', style: GoogleFonts.lato(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/scan');
            },
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.history, size: 30),
            label: Text('View Managed Transactions',
                style: GoogleFonts.lato(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/transactions');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome, Admin!',
            style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.supervised_user_circle, size: 30),
            label: Text('Manage Users', style: GoogleFonts.lato(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/manage_users');
            },
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.history, size: 30),
            label: Text('View All Transactions',
                style: GoogleFonts.lato(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/admin_transactions');
            },
          ),
        ],
      ),
    );
  }
}
