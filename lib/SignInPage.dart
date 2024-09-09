import 'package:flutter/material.dart';
import 'authservice.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _error = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) {
                  setState(() => _email = val);
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                onChanged: (val) {
                  setState(() => _password = val);
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      child: Text('Sign In'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          dynamic result =
                              await AuthService().signIn(_email, _password);
                          if (result == null) {
                            setState(() {
                              _error =
                                  'Could not sign in with those credentials';
                              _isLoading = false;
                            });
                          } else {
                            // Connexion réussie, vous pouvez rediriger l'utilisateur ou afficher un message de succès
                            Navigator.pop(
                                context); // Retour à la page précédente ou redirection
                          }
                        }
                      },
                    ),
              SizedBox(height: 12.0),
              Text(
                _error,
                style: TextStyle(color: Colors.red, fontSize: 14.0),
              ),
              SizedBox(height: 12.0),
              TextButton(
                child: Text("Don't have an account? Sign up here."),
                onPressed: () {
                  Navigator.pushNamed(context,
                      '/signup'); // Redirige vers la page d'inscription
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
