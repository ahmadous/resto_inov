import 'package:flutter/material.dart';
import 'authservice.dart'; // Remplacez par le chemin correct de votre AuthService

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
                    validator: (val) => val!.isEmpty ? 'Enter an email' : null,
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
                              dynamic result =
                                  await AuthService().signUp(_email, _password);
                              if (result == null) {
                                setState(() {
                                  _error =
                                      'Could not sign up with those credentials';
                                  _isLoading = false;
                                });
                              } else {
                                Navigator.pushReplacementNamed(context,
                                    '/'); // Remplacez '/home' par la route correcte
                              }
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
