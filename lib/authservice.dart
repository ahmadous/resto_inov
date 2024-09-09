import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Inscription avec email et mot de passe
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Ajouter l'utilisateur dans Firestore avec un rôle par défaut
      await _db.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'email': email,
        'role': 'student', // Rôle par défaut
        'balance': 0.0, // Solde initial
      });

      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Connexion avec email et mot de passe
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }

  // Vérifier l'état de connexion de l'utilisateur
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Récupérer les informations de l'utilisateur depuis Firestore
  Future<DocumentSnapshot> getUserData(String userId) async {
    return await _db.collection('users').doc(userId).get();
  }

  // Méthode pour mettre à jour le rôle de l'utilisateur (par exemple, admin, manager)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _db.collection('users').doc(userId).update({
        'role': newRole,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Méthode pour mettre à jour le solde de l'utilisateur
  Future<void> updateUserBalance(String userId, double amount) async {
    try {
      await _db.collection('users').doc(userId).update({
        'balance': FieldValue.increment(amount),
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
