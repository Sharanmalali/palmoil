import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atma_farm_app/models/community_post_model.dart';
import 'package:atma_farm_app/models/community_reply_model.dart';

class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gets a real-time stream of all community posts, ordered by most recent
  Stream<List<CommunityPost>> getPostsStream() {
    return _db
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList());
  }

  // Creates a new post in the forum
  Future<void> createPost(String text) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("You must be logged in to post.");
    }

    // We need the user's name, which is in the 'users' collection
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Anonymous Farmer';

    await _db.collection('community_posts').add({
      'authorId': user.uid,
      'authorName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Gets a real-time stream of replies for a specific post
  Stream<List<CommunityReply>> getRepliesStream(String postId) {
    return _db
        .collection('community_posts')
        .doc(postId)
        .collection('replies') // Accessing the subcollection of the post
        .orderBy('createdAt', descending: false) // Show oldest replies first for chat flow
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityReply.fromFirestore(doc))
            .toList());
  }

  // Adds a new reply to a specific post
  Future<void> addReply(String postId, String text) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("You must be logged in to reply.");
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Anonymous Farmer';

    await _db
        .collection('community_posts')
        .doc(postId)
        .collection('replies')
        .add({
          'authorId': user.uid,
          'authorName': userName,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}

