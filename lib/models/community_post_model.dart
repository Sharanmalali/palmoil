    import 'package:cloud_firestore/cloud_firestore.dart';

    class CommunityPost {
      final String id;
      final String authorName;
      final String authorId;
      final String text;
      final Timestamp createdAt;
      // We can add imageUrl, replies, etc. later

      CommunityPost({
        required this.id,
        required this.authorName,
        required this.authorId,
        required this.text,
        required this.createdAt,
      });

      factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return CommunityPost(
          id: doc.id,
          authorName: data['authorName'] ?? 'Anonymous',
          authorId: data['authorId'] ?? '',
          text: data['text'] ?? '',
          createdAt: data['createdAt'] ?? Timestamp.now(),
        );
      }
    }
    
