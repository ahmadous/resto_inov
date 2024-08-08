import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QrScannerPage extends StatefulWidget {
  @override
  _QrScannerPageState createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrCodeData;
  TextEditingController _amountController = TextEditingController();
  final String projectId = '712743378530';

  @override
  void dispose() {
    controller?.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner un QR Code'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal, width: 4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
              ),
            ),
          ),
          if (qrCodeData != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Entrez le montant',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _confirmTransaction,
              child: Text('Confirmer la transaction'),
            ),
          ],
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrCodeData = scanData.code;
        controller.pauseCamera();
      });
    });
  }

  void _confirmTransaction() {
    if (qrCodeData != null && _amountController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmer la Transaction'),
            content: Text(
                'Êtes-vous sûr de vouloir ajouter FCFA ${_amountController.text} au compte de cet utilisateur?'),
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
                  _saveTransaction();
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Veuillez scanner un code QR et entrer un montant.')),
      );
    }
  }

  Future<void> _saveTransaction() async {
    double? amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un montant valide.')),
      );
      return;
    }

    try {
      // Mise à jour du solde de l'utilisateur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(qrCodeData)
          .update({
        'balance': FieldValue.increment(amount),
      });

      // Enregistrement de la transaction
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': qrCodeData,
        'amount': amount,
        'date': DateTime.now(),
        'managerId': FirebaseAuth.instance.currentUser?.uid,
      });

      // Envoyer une notification push à l'utilisateur
      await _sendNotification(
          "Transaction reçue", "Vous avez reçu $amount FCFA");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction enregistrée avec succès!')),
      );

      setState(() {
        qrCodeData = null;
        _amountController.clear();
        controller?.resumeCamera();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Échec de l\'enregistrement de la transaction: $e')),
      );
    }
  }

  Future<void> _sendNotification(String title, String body) async {
    try {
      // Obtenez un nouveau token d'accès via l'API backend
      String accessToken = await fetchAccessToken();

      // Obtenez le token FCM de l'utilisateur scanné
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(qrCodeData)
          .get();
      String? fcmToken = snapshot['fcmToken'];

      if (fcmToken != null) {
        final url =
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
        final headers = {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $accessToken', // Utilisez le token OAuth 2.0 ici
        };

        final bodyData = {
          'message': {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            }
          }
        };

        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(bodyData),
        );

        if (response.statusCode == 200) {
          print('Notification envoyée avec succès.');
        } else {
          print(
              'Erreur lors de l\'envoi de la notification: ${response.statusCode}');
          print('Détails: ${response.body}');
        }
      } else {
        print("Token FCM non trouvé pour l'utilisateur.");
      }
    } catch (e) {
      print("Erreur lors de l'envoi de la notification : $e");
    }
  }

  Future<String> fetchAccessToken() async {
    final response =
        await http.get(Uri.parse('https://your-backend.com/get-token'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['accessToken'];
    } else {
      throw Exception('Erreur lors de la récupération du token');
    }
  }
}
