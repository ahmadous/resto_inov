import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _error = '';
  bool _isLoading = false;

  final List<String> allowedDomains = ['univ-thies.sn', 'ucad.sn'];

  bool isAllowedDomain(String email) {
    final domain = email.split('@').last;
    return allowedDomains.contains(domain);
  }

  Future<void> _createUserInFirestore(User user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Check if the user document already exists
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      // Create the user document if it doesn't exist
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'role': 'user', // You can modify the default role if necessary
        'balance': 0,   // Initialize balance or other fields
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign Up',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                  SizedBox(height: 40),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) {
                      if (val!.isEmpty) {
                        return 'Enter an email';
                      } else if (!isAllowedDomain(val)) {
                        return 'Email domain must be @univ-thies.sn or @ucad.sn';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      setState(() => _email = val);
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                    validator: (val) => val!.length < 6
                        ? 'Enter a password 6+ chars long'
                        : null,
                    onChanged: (val) {
                      setState(() => _password = val);
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                    validator: (val) =>
                    val != _password ? 'Passwords do not match' : null,
                    onChanged: (val) {
                      setState(() => _confirmPassword = val);
                    },
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.teal[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);
                        try {
                          UserCredential result = await FirebaseAuth
                              .instance
                              .createUserWithEmailAndPassword(
                              email: _email, password: _password);

                          // Call method to create user in Firestore
                          await _createUserInFirestore(result.user!);

                          Navigator.pushReplacementNamed(
                              context, '/');
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'email-already-in-use') {
                            setState(() {
                              _error = 'This email is already in use.';
                              _isLoading = false;
                            });
                          } else {
                            setState(() {
                              _error =
                              'An error occurred. Please try again.';
                              _isLoading = false;
                            });
                          }
                        }
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  TextButton.icon(
                    icon: Icon(Icons.login, color: Colors.teal[700]),
                    label: Text(
                      'Sign Up with Google',
                      style: TextStyle(color: Colors.teal[700]),
                    ),
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        GoogleSignInAccount? googleUser =
                        await GoogleSignIn().signIn();
                        if (googleUser != null) {
                          final emailDomain = googleUser.email.split('@').last;
                          if (allowedDomains.contains(emailDomain)) {
                            GoogleSignInAuthentication googleAuth =
                            await googleUser.authentication;
                            final AuthCredential credential =
                            GoogleAuthProvider.credential(
                              accessToken: googleAuth.accessToken,
                              idToken: googleAuth.idToken,
                            );
                            UserCredential result = await FirebaseAuth.instance
                                .signInWithCredential(credential);

                            // Call method to create user in Firestore
                            await _createUserInFirestore(result.user!);

                            Navigator.pushReplacementNamed(context, '/');
                          } else {
                            setState(() {
                              _error =
                              'Only @univ-thies.sn or @ucad.sn emails are allowed.';
                              _isLoading = false;
                            });
                            await GoogleSignIn().signOut();
                          }
                        }
                      } catch (e) {
                        setState(() {
                          _error = 'Google Sign-In failed. Try again.';
                          _isLoading = false;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 12.0),
                  Center(
                    child: Text(
                      _error,
                      style: TextStyle(color: Colors.red, fontSize: 14.0),
                    ),
                  ),
                  SizedBox(height: 12.0),
                  TextButton(
                    child: Text(
                      "Already have an account? Sign in here.",
                      style: TextStyle(color: Colors.teal[700]),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
