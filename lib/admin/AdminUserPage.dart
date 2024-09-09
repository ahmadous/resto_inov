import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUserPage extends StatefulWidget {
  @override
  _AdminUserPageState createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  String searchQuery = "";
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Utilisateurs'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher par email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aucun utilisateur trouvé.'));
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var email =
                      (doc.data() as Map<String, dynamic>)['email'] ?? '';
                  return email.toLowerCase().contains(searchQuery);
                }).toList();

                return ListView(
                  children: filteredDocs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    var email = data['email'];
                    var tickets = data['tickets'] ?? [];
                    var role = data['role'] ?? 'student';

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      child: ListTile(
                        leading: Icon(Icons.person, color: Colors.blueAccent),
                        title: Text('Utilisateur : $email',
                            style: GoogleFonts.lato(fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tickets : ${tickets.length}',
                              style: GoogleFonts.lato(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  'Rôle : ',
                                  style: GoogleFonts.lato(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                                DropdownButton<String>(
                                  value: role,
                                  items: <String>['student', 'manager', 'admin']
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (currentUser != null &&
                                          currentUser!.email == email &&
                                          role == 'admin')
                                      ? null
                                      : (String? newRole) {
                                          if (newRole != null) {
                                            _confirmRoleChange(context, doc.id,
                                                newRole, email);
                                          }
                                        },
                                ),
                              ],
                            ),
                          ],
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
  }

  void _confirmRoleChange(
      BuildContext context, String userId, String newRole, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changer le Rôle'),
          content: Text(
              'Êtes-vous sûr de vouloir changer le rôle de $email en $newRole ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirmer'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateUserRole(userId, newRole);
              },
            ),
          ],
        );
      },
    );
  }

  void _updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Le rôle de l\'utilisateur a été mis à jour en $newRole')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la mise à jour du rôle : $e')),
      );
    }
  }
}
