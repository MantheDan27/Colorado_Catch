import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../widgets/loading_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSaving = false;

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final downloadUrl = await storageService.uploadProfileImage(user.uid, File(picked.path));
    await firestore.saveUserProfile(UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: downloadUrl,
    ));

    if (!mounted) return;
    setState(() => _isSaving = false);
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
              ElevatedButton(onPressed: _uploadImage, child: const Text('Upload Profile Photo')),
              if (_isSaving) const Padding(padding: EdgeInsets.only(top: 16), child: LoadingIndicator()),
            ],
          ),
        );
      },
    );
  }
}
