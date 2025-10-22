import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/farm_model.dart';
import 'package:atma_farm_app/screens/home_screen.dart';
import 'package:atma_farm_app/screens/wallet_screen.dart';
import 'package:atma_farm_app/screens/market_screen.dart';
import 'package:atma_farm_app/screens/community_screen.dart';
import 'package:atma_farm_app/screens/ai_advisor_screen.dart';
import 'package:atma_farm_app/screens/pest_scanner_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends StatefulWidget {
  final Farm farm;
  const MainScreen({super.key, required this.farm});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  final List<String> _screenTitles = ['Home', 'My Wallet', 'Market', 'Community', 'AI Advisor'];

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListeningForNavigation = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _screens = [
      HomeScreen(farm: widget.farm),
      const WalletScreen(),
      MarketScreen(farm: widget.farm),
      const CommunityScreen(),
      const AiAdvisorScreen(),
    ];
  }

  Future<void> _initSpeech() async {
    bool micPermissionGranted = await _requestMicrophonePermission();
    bool speechAvailable = false;
    if (micPermissionGranted) {
      try {
        speechAvailable = await _speechToText.initialize(
          onError: (errorNotification) => print('STT Nav Error: ${errorNotification.errorMsg}'),
          onStatus: (status) {
            print('STT Nav Status: $status');
            if (mounted) {
              setState(() {
                _isListeningForNavigation = _speechToText.isListening;
              });
            }
          }
        );
      } catch (e) {
         print("Error initializing SpeechToText: $e");
         speechAvailable = false;
      }
    } else {
      print("Microphone permission denied.");
    }

    if (mounted) {
      setState(() {
        _speechEnabled = speechAvailable;
      });
      // Don't show snackbar on init, only when user tries to use it and fails
      // if (!_speechEnabled) {
      //    _showSnackbar('Speech recognition not available or permission denied.');
      // }
    }
  }

  Future<bool> _requestMicrophonePermission() async {
     var status = await Permission.microphone.request();
     return status.isGranted;
  }

  void _startListeningForNavigation() async {
    if (!_speechEnabled) {
       _showSnackbar('Speech recognition not available. Please ensure microphone permission is granted.');
       await _initSpeech();
       return;
    }
    if (_isListeningForNavigation) return;

    setState(() => _isListeningForNavigation = true);
    _showSnackbar('Listening...');

    _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
           _handleVoiceCommand(result.recognizedWords);
           // Status callback should handle setting listening to false
           // if (mounted) setState(() => _isListeningForNavigation = false);
        }
      },
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      localeId: "en_IN",
      cancelOnError: true,
      partialResults: false,
    ).catchError((error) {
       print("Error during listen: $error");
       if (mounted) {
          setState(() => _isListeningForNavigation = false);
          _showSnackbar('Listening failed. Please try again.');
       }
    });
  }

  void _stopListeningForNavigation() async {
    if (!_isListeningForNavigation) return;
    await _speechToText.stop();
    // Status callback should handle setting listening to false
    // setState(() => _isListeningForNavigation = false);
  }

  void _handleVoiceCommand(String command) {
    // Ensure listening state is false after command processing
    if (mounted) setState(() => _isListeningForNavigation = false);

    final lowerCaseCommand = command.toLowerCase().trim();
    print("Recognized command: $lowerCaseCommand");

    const Map<String, int> navigationKeywords = {
      'home': 0, 'dashboard': 0,
      'wallet': 1, 'finance': 1, 'money': 1, 'subsidy': 1,
      'market': 2, 'sell': 2, 'pickup': 2,
      'community': 3, 'forum': 3, 'chaupal': 3, 'post': 3,
      'advisor': 4, 'chat': 4, 'assistant': 4, 'advice': 4,
    };
    const List<String> scannerKeywords = ['scan', 'pest', 'disease', 'problem', 'leaf'];

    int targetIndex = -1;
    bool scannerAction = false;

    for (var keyword in navigationKeywords.keys) {
      if (lowerCaseCommand.contains(keyword)) {
        targetIndex = navigationKeywords[keyword]!;
        break;
      }
    }

    if (targetIndex == -1) {
      for (var keyword in scannerKeywords) {
        if (lowerCaseCommand.contains(keyword)) {
          scannerAction = true;
          break;
        }
      }
    }

    if (targetIndex != -1) {
      if (targetIndex != _selectedIndex) {
        _onItemTapped(targetIndex);
        _showSnackbar('Navigating to ${_screenTitles[targetIndex]}...');
      } else {
        _showSnackbar('Already on the ${_screenTitles[targetIndex]} screen.');
      }
    } else if (scannerAction) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PestScannerScreen()));
      _showSnackbar('Opening Pest Scanner...');
    } else {
      _showSnackbar('Command not understood: "$command"');
    }
  }

  void _showSnackbar(String message) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the AppBar background color from the theme
    final appBarTheme = AppBarTheme.of(context);
    // Use theme brightness to decide icon color (black for light themes, white for dark)
    final Brightness brightness = appBarTheme.systemOverlayStyle?.statusBarBrightness ?? Theme.of(context).brightness;
    final Color defaultIconColor = brightness == Brightness.dark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: Icon(
              _isListeningForNavigation ? Icons.mic_off : Icons.mic,
              // ** THE CHANGE IS HERE **
              // Use black as default, red when listening
              color: _isListeningForNavigation ? Colors.red : defaultIconColor,
            ),
            tooltip: 'Tap to speak navigation command',
            onPressed: _speechEnabled
              ? (_isListeningForNavigation ? _stopListeningForNavigation : _startListeningForNavigation)
              : () => _showSnackbar('Speech recognition not available.'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.house), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.wallet), label: 'My Wallet'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.shop), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.users), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.brain), label: 'AI Advisor'),
        ],
      ),
    );
  }

   @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }
}

