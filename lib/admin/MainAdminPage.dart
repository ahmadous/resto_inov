import 'package:flutter/material.dart';
import '../authservice.dart';
import 'AdminDashboardPage.dart';
import 'AdminTransactionPage.dart';
import 'AdminUserPage.dart';

class MainAdminPage extends StatefulWidget {
  @override
  _MainAdminPageState createState() => _MainAdminPageState();
}

class _MainAdminPageState extends State<MainAdminPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    AdminDashboardPage(),
    AdminTransactionPage(),
    AdminUserPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _signOut() async {
    await AuthService().signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.teal,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.teal[200],
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
