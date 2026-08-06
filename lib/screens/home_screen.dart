import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/push_service.dart';
import 'catch_capture_screen.dart';
import 'chat_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Map is the home/default tab. Order matches the nav bar's left-to-right
  // layout below (two destinations either side of the center camera notch).
  final _tabs = const [
    MapScreen(),
    LeaderboardScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _registerPushToken();
  }

  Future<void> _registerPushToken() async {
    final pushService = Provider.of<PushService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final token = await pushService.getDeviceToken();
    if (!mounted || token == null) return;

    final user = authService.currentUser;
    if (user != null) {
      await firestoreService.updatePushToken(user.uid, token);
    }
  }

  void _openCatchCapture() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatchCaptureScreen()));
  }

  Widget _navIcon(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    final color = selected ? Theme.of(context).primaryColor : Colors.grey;
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: label,
      onPressed: () => setState(() => _currentIndex = index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colorado Catch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: authService.signOut,
          )
        ],
      ),
      body: _tabs[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _openCatchCapture,
        tooltip: 'Log a catch',
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navIcon(Icons.map, 'Map', 0),
            _navIcon(Icons.leaderboard, 'Leaderboard', 1),
            const SizedBox(width: 48), // reserved for the notch
            _navIcon(Icons.chat, 'Chat', 2),
            _navIcon(Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }
}
