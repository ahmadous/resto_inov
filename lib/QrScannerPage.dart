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

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrCodeData;
  int _selectedMultiplier = 1;
  String _selectedAction = 'Créditer';
  bool _showOptions = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final String projectId = '712743378530';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController!);
  }

  @override
  void dispose() {
    controller?.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildScannerSection(),
            if (qrCodeData != null) ...[
              SizedBox(height: 20),
              _buildAnimatedOptions(),
              SizedBox(height: 20),
              _buildConfirmButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannerSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal, width: 4),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
                _buildScanOverlay(),
              ],
            ),
          ),
          SizedBox(height: 10),
          Text(
            qrCodeData != null
                ? 'QR Code Scanné : $qrCodeData'
                : 'Scannez un QR Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return qrCodeData == null
        ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code_scanner, size: 100, color: Colors.white70),
        Text(
          'Placez le QR Code ici',
          style: TextStyle(
              color: Colors.white70, fontWeight: FontWeight.bold),
        ),
      ],
    )
        : Container();
  }

  Widget _buildAnimatedOptions() {
    _animationController!.forward();
    return FadeTransition(
      opacity: _animation!,
      child: Column(
        children: [
          Text(
            'Action à effectuer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ToggleButtons(
            borderRadius: BorderRadius.circular(10),
            isSelected: [_selectedAction == 'Créditer', _selectedAction == 'Débiter'],
            onPressed: (index) {
              setState(() {
                _selectedAction = index == 0 ? 'Créditer' : 'Débiter';
                _showOptions = true;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Créditer'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Débiter'),
              ),
            ],
          ),
          if (_showOptions) ...[
            SizedBox(height: 20),
            _buildAmountSelection(),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountSelection() {
    return Column(
      children: [
        Text(
          _selectedAction == 'Débiter'
              ? 'Sélectionnez le montant à débiter'
              : 'Montant à créditer',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 10),
        _selectedAction == 'Débiter'
            ? _buildDebitOptions()
            : _buildCreditInput(),
      ],
    );
  }

  Widget _buildDebitOptions() {
    return Column(
      children: [
        Text(
          'Choisissez le montant de chaque débit',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _selectDebitAmount(context),
          child: Text('50 FCFA ou 100 FCFA'),
        ),
        SizedBox(height: 10),
        Text(
          'Nombre de fois à débiter (par défaut : 1)',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle),
              onPressed: () {
                setState(() {
                  if (_selectedMultiplier > 1) {
                    _selectedMultiplier--;
                  }
                });
              },
            ),
            Text(
              '$_selectedMultiplier',
              style: TextStyle(fontSize: 18),
            ),
            IconButton(
              icon: Icon(Icons.add_circle),
              onPressed: () {
                setState(() {
                  _selectedMultiplier++;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditInput() {
    return Column(
      children: [
        SizedBox(height: 10),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Montant en FCFA',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _selectedMultiplier = int.tryParse(value)!;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          _confirmTransaction(context);
        },
        child: Text('Confirmer la Transaction'),
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

  void _selectDebitAmount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sélectionner le Montant à Débiter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('50 FCFA'),
                onTap: () => _confirmTransaction(context, 50),
              ),
              ListTile(
                title: Text('100 FCFA'),
                onTap: () => _confirmTransaction(context, 100),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmTransaction(BuildContext context, [double baseAmount = 0]) {
    double totalAmount = baseAmount * _selectedMultiplier;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la Transaction'),
          content: Text(
            'Vous allez ${_selectedAction.toLowerCase()} '
                '${totalAmount == 0 ? _selectedMultiplier : totalAmount} FCFA',
          ),
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
                _saveTransaction(totalAmount);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTransaction(double amount) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(qrCodeData)
          .update({
        'balance': _selectedAction == 'Créditer'
            ? FieldValue.increment(amount)
            : FieldValue.increment(-amount),
      });

      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': qrCodeData,
        'amount': amount,
        'date': DateTime.now(),
        'managerId': FirebaseAuth.instance.currentUser?.uid,
        'type': _selectedAction == 'Créditer' ? 'credit' : 'debit',
      });

      _askToContinue();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de l\'enregistrement de la transaction: $e')),
      );
    }
  }

  void _askToContinue() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Continuer le Scan?'),
          content: Text('Voulez-vous scanner un autre code QR ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Non'),
              onPressed: () {
                Navigator.of(context).pop();
                controller?.dispose();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Oui'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  qrCodeData = null;
                  controller?.resumeCamera();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
