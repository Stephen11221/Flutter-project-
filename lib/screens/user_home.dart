import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'UserProfileScreen.dart';
import 'UserSettingsScreen.dart';
import 'drawer_menu.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> stories = [];
  List<Map<String, dynamic>> filteredStories = [];
  final Map<String, bool> expandedMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToStories();
  }

  void _listenToStories() {
    FirebaseFirestore.instance.collection('story').snapshots().listen((snapshot) {
      final newStories = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (stories.isNotEmpty && newStories.length > stories.length) {
        final added = newStories.length - stories.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$added new stor${added == 1 ? "y" : "ies"} added'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        stories = List<Map<String, dynamic>>.from(newStories);
        _filterStories();
        for (var story in stories) {
          expandedMap[story['id']] ??= false;
        }
        isLoading = false;
      });
    });
  }

  void _filterStories() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredStories = stories.where((story) {
        final title = (story['title'] ?? '').toLowerCase();
        final content = (story['content'] ?? '').toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
    });
  }

  void _rateStory(String storyId, int rating) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('rating').doc(storyId).set({
      'ratings': {uid: rating}
    }, SetOptions(merge: true));
  }

  void _showCommentDialog(String storyId) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: 'Write your comment...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final comment = commentController.text.trim();
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (comment.isNotEmpty && uid != null) {
                await FirebaseFirestore.instance
                    .collection('story')
                    .doc(storyId)
                    .update({
                  'comments': FieldValue.arrayUnion([
                    {
                      'userId': uid,
                      'text': comment,
                      'timestamp': Timestamp.now(),
                    }
                  ])
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('story')
        .orderBy('lastUpdated', descending: true)
        .limit(5)
        .get();

    final updatedStories = snapshot.docs.where((doc) {
      final data = doc.data();
      return data.containsKey('lastUpdated') &&
          data['lastUpdated'] != null &&
          data['timestamp'] != null &&
          (data['lastUpdated'] as Timestamp).compareTo(data['timestamp']) > 0;
    }).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.notifications, color: Colors.green),
                title: Text("New story added!"),
              ),
              const ListTile(
                leading: Icon(Icons.notifications, color: Colors.green),
                title: Text("Don't forget to check your favorites."),
              ),
              if (updatedStories.isNotEmpty) const Divider(),
              ...updatedStories.map((doc) {
                final data = doc.data();
                return ListTile(
                  leading: const Icon(Icons.edit, color: Colors.red),
                  title: Text(
                    '${data['title'] ?? 'Story'} has been updated',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Reader Home'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Stories",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by title or content',
                          prefixIcon: const Icon(Icons.search, color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                        ),
                        onChanged: (_) => _filterStories(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredStories.isEmpty
                      ? const Center(child: Text("No stories found"))
                      : ListView.builder(
                          itemCount: filteredStories.length,
                          itemBuilder: (context, index) {
                            final story = filteredStories[index];
                            final storyId = story['id'];
                            final isExpanded = expandedMap[storyId] ?? false;
                            final ratings = (story['ratings'] as Map?)?.values.cast<int>().toList() ?? [];
                            final avgRating = ratings.isNotEmpty
                                ? ratings.reduce((a, b) => a + b) / ratings.length
                                : 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: story['imageUrl'] != null
                                          ? Image.network(
                                              story['imageUrl'],
                                              width: 60,
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(Icons.book, size: 40, color: Colors.green),
                                      title: Text(
                                        story['title'] ?? 'Untitled',
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                      subtitle: Text("Avg Rating: ${avgRating.toStringAsFixed(1)} / 5"),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      story['content'] ?? 'No content',
                                      maxLines: isExpanded ? null : 3,
                                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            expandedMap[storyId] = !isExpanded;
                                          });
                                        },
                                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                                        child: Text(isExpanded ? 'Collapse' : 'Expand'),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(5, (i) {
                                        final uid = FirebaseAuth.instance.currentUser?.uid;
                                        final userRating = (story['ratings'] ?? {})[uid] ?? 0;
                                        return IconButton(
                                          icon: Icon(
                                            i < userRating ? Icons.star : Icons.star_border,
                                            color: Colors.orange,
                                          ),
                                          onPressed: () => _rateStory(storyId, i + 1),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("Comments:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ...((story['comments'] ?? []) as List<dynamic>)
                                        .take(2)
                                        .map((comment) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                                              child: Text("- ${comment['text']}"),
                                            )),
                                    TextButton(
                                      onPressed: () => _showCommentDialog(storyId),
                                      child: const Text('Add Comment'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
