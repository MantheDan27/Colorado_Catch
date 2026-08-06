import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/push_service.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _tabs = const [
    ProfileScreen(),
    MapScreen(),
    ChatScreen(),
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
      await firestoreService.profiles.doc(user.uid).set({'pushToken': token}, SetOptions(merge: true));
    }
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
