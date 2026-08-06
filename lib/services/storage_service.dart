import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String uid, File file) async {
    final ref = _storage.ref().child('profile_images').child('$uid.jpg');
    final uploadTask = ref.putFile(file);
    await uploadTask.whenComplete(() {});
    return ref.getDownloadURL();
  }
}
