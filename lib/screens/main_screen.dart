import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/farm_model.dart';
import 'package:atma_farm_app/screens/home_screen.dart';
import 'package:atma_farm_app/screens/wallet_screen.dart';
import 'package:atma_farm_app/screens/market_screen.dart';
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
    _screens = [
      HomeScreen(farm: widget.farm),
      const WalletScreen(),
      // ** THE FIX IS HERE **
      // We now pass the farm object to the MarketScreen as required.
      MarketScreen(farm: widget.farm), 
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
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.shop),
            label: 'Market',
          ),
        ],
      ),
    );
  }
}

