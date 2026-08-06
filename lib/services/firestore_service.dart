import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get profiles => _firestore.collection('profiles');
  CollectionReference get chats => _firestore.collection('chats');
  CollectionReference get locations => _firestore.collection('locations');

  Future<void> saveUserProfile(UserProfile profile) {
    return profiles.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Stream<UserProfile?> userProfileStream(String uid) {
    return profiles.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(uid, snapshot.data()! as Map<String, dynamic>);
      }
      return null;
    });
  }

  Stream<QuerySnapshot> chatMessages(String roomId) {
    return chats.doc(roomId).collection('messages').orderBy('createdAt', descending: false).snapshots();
  }

  Future<void> sendMessage(String roomId, Map<String, dynamic> message) {
    return chats.doc(roomId).collection('messages').add(message);
  }

  Future<void> addLocation(String id, Map<String, dynamic> location) {
    return locations.doc(id).set(location);
  }
}
