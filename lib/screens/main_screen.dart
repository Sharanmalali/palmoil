import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/farm_model.dart';
import 'package:atma_farm_app/screens/home_screen.dart';
import 'package:atma_farm_app/screens/wallet_screen.dart'; // Import the new WalletScreen
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainScreen extends StatefulWidget {
  final Farm farm;
  const MainScreen({super.key, required this.farm});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Define the screens that the bottom navigation bar will switch between
    _screens = [
      HomeScreen(farm: widget.farm), // Our existing dashboard
      const WalletScreen(),       // The real wallet screen from your Canvas
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.wallet),
            label: 'My Wallet',
          ),
        ],
      ),
    );
  }
}

