import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile photo upload is stubbed out until Cloud Storage is provisioned
  // (requires the Blaze plan) — see StorageService and SETUP.md.
  void _showUploadComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo upload is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('No user available'));
    }

    return StreamBuilder<UserProfile?>(
      stream: Provider.of<FirestoreService>(context).userProfileStream(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundImage: profile?.photoUrl != null ? NetworkImage(profile!.photoUrl!) : null,
                child: profile?.photoUrl == null ? const Icon(Icons.person, size: 48) : null,
              ),
              const SizedBox(height: 16),
              Text(profile?.displayName ?? user.displayName ?? 'Colorado Angler', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(user.email ?? ''),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _showUploadComingSoon,
                child: const Text('Upload Profile Photo (coming soon)'),
              ),
            ],
          ),
        );
      },
    );
  }
}
