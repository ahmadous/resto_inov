import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyQrCodePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My QR Code'),
        ),
        body: Center(
          child: Text('No user logged in.'),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('My QR Code')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('My QR Code')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text('My QR Code')),
            body: Center(child: Text('User data not found.')),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        if (userData['role'] != 'student') {
          return Scaffold(
            appBar: AppBar(title: Text('My QR Code')),
            body: Center(child: Text('Only students can generate QR codes.')),
          );
        }

        final String qrData = user.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text('My QR Code'),
          ),
          body: Center(
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        );
      },
    );
  }
}
