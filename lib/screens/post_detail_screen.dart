import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/community_post_model.dart';
import 'package:atma_farm_app/models/community_reply_model.dart';
import 'package:atma_farm_app/services/community_service.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final text = _replyController.text.trim();
    _replyController.clear();

    try {
      await _communityService.addReply(widget.post.id, text);
      // Scroll to bottom after sending
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e')),
      );
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // The original post
                SliverToBoxAdapter(
                  child: OriginalPostWidget(post: widget.post),
                ),
                // The stream of replies
                StreamBuilder<List<CommunityReply>>(
                  stream: _communityService.getRepliesStream(widget.post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text('Be the first to reply.')),
                        ),
                      );
                    }
                    final replies = snapshot.data!;
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ReplyWidget(reply: replies[index]),
                        childCount: replies.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // The reply input field
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: const InputDecoration(
                  hintText: 'Write a reply...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: _sendReply,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to display the original post
class OriginalPostWidget extends StatelessWidget {
  final CommunityPost post;
  const OriginalPostWidget({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(post.authorName.isNotEmpty ? post.authorName[0] : 'A'),
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
          const SizedBox(height: 16),
          Text(post.text, style: const TextStyle(fontSize: 18)),
          const Divider(height: 32),
          const Text("Replies", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Widget to display a single reply
class ReplyWidget extends StatelessWidget {
  final CommunityReply reply;
  const ReplyWidget({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(reply.authorName.isNotEmpty ? reply.authorName[0] : 'A', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(reply.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
