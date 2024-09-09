import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'student/StudentHomePage.dart';
import 'manager/ManagerHomePage.dart';
import 'LoginPage.dart';
import 'admin/MainAdminPage.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // Si l'utilisateur n'est pas connecté, redirigez vers la page de connexion
    if (user == null) {
      return LoginPage();
    } else {
      // Récupérer les données de l'utilisateur à partir de Firestore
      return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
              body: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('User data not found.'),
                  ElevatedButton(onPressed:
                  ()=>Navigator.push(context,MaterialPageRoute(builder: (context)=>LoginPage())), child: Text("voulez vous retourner a la page de connexion"))
                ],
              )),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var role = userData['role'];

          // Rediriger vers la page appropriée en fonction du rôle de l'utilisateur
          if (role == 'student') {
            return StudentHomePage();
          } else if (role == 'manager') {
            return ManagerHomePage();
          } else if (role == 'admin') {
            return MainAdminPage(); // Page avec le BottomNavigationBar pour les admins
          } else {
            return Scaffold(
              body: Center(child: Text('Error: Invalid role.')),
            );
          }
        },
      );
    }
  }
}
