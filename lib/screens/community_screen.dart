import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/community_post_model.dart';
import 'package:atma_farm_app/services/community_service.dart';
import 'package:atma_farm_app/screens/new_post_screen.dart';
import 'package:atma_farm_app/screens/post_detail_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Chaupal'),
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: _communityService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No posts yet. Be the first to ask a question!'),
            );
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NewPostScreen()),
          );
        },
        child: const Icon(Icons.add_comment),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final CommunityPost post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell( // Make the whole card tappable to view details/replies
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(post.authorName.isNotEmpty ? post.authorName[0] : 'A',
                      style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(post.createdAt.toDate()),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                post.text, 
                style: const TextStyle(fontSize: 16),
                maxLines: 4, // Limit the number of lines shown in the feed
                overflow: TextOverflow.ellipsis, // Add '...' for long posts
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.reply, size: 16),
                    label: const Text('Reply'),
                    onPressed: () {
                      // This button now correctly navigates to the detail screen
                       Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

