import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  double _totalAmount = 0;
  int _transactionCount = 0;
  double _averageAmount = 0;
  int _userCount = 0;
  Map<String, int> _roleDistribution = {'student': 0, 'manager': 0, 'admin': 0};
  List<PieChartData> _chartData = [];

  @override
  void initState() {
    super.initState();
    _calculateDashboardStats();
  }

  void _calculateDashboardStats() async {
    QuerySnapshot transactionSnapshot =
        await FirebaseFirestore.instance.collection('transactions').get();
    QuerySnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    double totalAmount = 0;
    int transactionCount = transactionSnapshot.docs.length;

    Map<String, int> roleDistribution = {
      'student': 0,
      'manager': 0,
      'admin': 0
    };

    for (var doc in transactionSnapshot.docs) {
      double amount = doc['amount'];
      totalAmount += amount;
    }

    for (var doc in userSnapshot.docs) {
      var role = doc['role'] ?? 'student';
      if (roleDistribution.containsKey(role)) {
        roleDistribution[role] = roleDistribution[role]! + 1;
      }
    }

    setState(() {
      _totalAmount = totalAmount;
      _transactionCount = transactionCount;
      _averageAmount =
          transactionCount > 0 ? totalAmount / transactionCount : 0;
      _userCount = userSnapshot.docs.length;
      _roleDistribution = roleDistribution;

      _chartData = [
        PieChartData('Étudiants', roleDistribution['student']!, Colors.blue),
        PieChartData(
            'Gestionnaires', roleDistribution['manager']!, Colors.green),
        PieChartData('Admins', roleDistribution['admin']!, Colors.red),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de Bord Admin'),
        backgroundColor: Colors.greenAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatsCard(),
              SizedBox(height: 20),
              _buildUserStatsCard(),
              SizedBox(height: 20),
              _buildRoleDistributionChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montant Total : ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(_totalAmount)}',
              style: GoogleFonts.lato(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Nombre Total de Transactions : $_transactionCount',
              style: GoogleFonts.lato(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Montant Moyen par Transaction : ${NumberFormat.currency(locale: 'fr', symbol: 'FCFA ').format(_averageAmount)}',
              style: GoogleFonts.lato(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nombre Total d\'Utilisateurs : $_userCount',
              style: GoogleFonts.lato(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Étudiants : ${_roleDistribution['student']}',
              style: GoogleFonts.lato(fontSize: 16),
            ),
            Text(
              'Gestionnaires : ${_roleDistribution['manager']}',
              style: GoogleFonts.lato(fontSize: 16),
            ),
            Text(
              'Admins : ${_roleDistribution['admin']}',
              style: GoogleFonts.lato(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDistributionChart() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition des Rôles des Utilisateurs',
              style: GoogleFonts.lato(fontSize: 18),
            ),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: Legend(isVisible: true),
                series: <PieSeries<PieChartData, String>>[
                  PieSeries<PieChartData, String>(
                    dataSource: _chartData,
                    xValueMapper: (PieChartData data, _) => data.category,
                    yValueMapper: (PieChartData data, _) => data.count,
                    pointColorMapper: (PieChartData data, _) => data.color,
                    dataLabelMapper: (PieChartData data, _) =>
                        '${data.category} : ${data.count}',
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PieChartData {
  PieChartData(this.category, this.count, this.color);
  final String category;
  final int count;
  final Color color;
}
