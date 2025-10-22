import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/farm_model.dart';
import 'package:atma_farm_app/screens/home_screen.dart';
import 'package:atma_farm_app/screens/wallet_screen.dart';
import 'package:atma_farm_app/screens/market_screen.dart';
import 'package:atma_farm_app/screens/community_screen.dart';
import 'package:atma_farm_app/screens/ai_advisor_screen.dart'; // Import the new AI screen
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
      MarketScreen(farm: widget.farm),
      const CommunityScreen(),
      const AiAdvisorScreen(), // Add the new AI Advisor screen
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
        // Use fixed type when there are more than 3 items to keep labels visible
        type: BottomNavigationBarType.fixed, 
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
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.users),
            label: 'Community',
          ),
          // Add the 5th item for the AI Advisor
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.brain), 
            label: 'AI Advisor',
          ),
        ],
      ),
    );
  }
}

