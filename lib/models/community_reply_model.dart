import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityReply {
  final String id;
  final String authorName;
  final String authorId;
  final String text;
  final Timestamp createdAt;

  CommunityReply({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  factory CommunityReply.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityReply(
      id: doc.id,
      authorName: data['authorName'] ?? 'Anonymous',
      authorId: data['authorId'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
