import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/push_service.dart';
import '../theme/colorado_catch_theme.dart';
import '../widgets/points_pill.dart';
import 'catch_capture_screen.dart';
import 'catch_log_screen.dart';
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
  // Chat was dropped from this build's IA — see the Colorado Catch, redesigned
  // design doc; ChatScreen/its Firestore-backed chat room still exist in the
  // codebase, just unreferenced here.
  final _tabs = const [
    MapScreen(),
    LeaderboardScreen(),
    CatchLogScreen(),
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

  Future<void> _openCatchCapture() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CatchCaptureScreen()),
    );
    // The Done screen's "Back to the map" button pops with this sentinel so
    // it lands on the Map tab even if the FAB was tapped from another tab.
    if (result == 'toMap' && mounted) setState(() => _currentIndex = 0);
  }

  Widget _navIcon(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    final color = selected ? AppColors.forest : const Color(0xFF8A968F);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final uid = authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 56,
        actions: [
          if (uid != null) PointsPill(uid: uid),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: authService.signOut,
          )
        ],
      ),
      body: _tabs[_currentIndex],
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.forest,
          border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 4)),
          boxShadow: [BoxShadow(color: Color(0x5A0F3D33), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: IconButton(
          onPressed: _openCatchCapture,
          tooltip: 'Log a catch',
          icon: const Icon(Icons.camera_alt, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        height: 80,
        color: Colors.white,
        child: Row(
          children: [
            _navIcon(Icons.map_outlined, 'Map', 0),
            _navIcon(Icons.leaderboard_outlined, 'Board', 1),
            const SizedBox(width: 56), // reserved for the notch
            _navIcon(Icons.receipt_long_outlined, 'Log', 2),
            _navIcon(Icons.person_outline, 'You', 3),
          ],
        ),
      ),
    );
  }
}
