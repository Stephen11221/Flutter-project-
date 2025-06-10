// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Editcreen.dart';
import 'change_password_screen.dart';
import 'user_home.dart';
import 'ViewAllStoriesScreen.dart';
import 'StoryCommentsScreen.dart';

class AdminStoryScreen extends StatefulWidget {
  const AdminStoryScreen({super.key});

  @override
  State<AdminStoryScreen> createState() => _AdminStoryScreenState();
}

class _AdminStoryScreenState extends State<AdminStoryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPosting = false;
  bool _isSuccess = false;

  List<String> notifications = [
    "New user joined.",
    "Story approved successfully.",
    "System update scheduled.",
  ];
  

  void _postStory() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;

    setState(() {
      _isPosting = true;
      _isSuccess = false;
    });

    await FirebaseFirestore.instance.collection('story').add({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'postedBy': 'Admin',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isPosting = false;
      _isSuccess = true;
      _titleController.clear();
      _contentController.clear();
    });
  }

  void _navigateToChangePassword() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
  }

  void _navigateToViewStoriesScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ViewAllStoriesScreen()));
  }

  void _navigateToUserHome() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UserHome()));
  }

  void _navigateToStoryCommentsScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ViewCommentsScreen(storyId: '',)));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              ...notifications.map((msg) => ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.green),
                    title: Text(msg),
                  )),

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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final greenColor = Colors.green;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: greenColor),
              accountName: Text(user?.displayName ?? 'Admin User'),
              accountEmail: Text(user?.email ?? 'admin@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 42, color: greenColor),
              ),
            ),
            ListTile(
              leading: Icon(Icons.book_online_sharp, color: greenColor),
              title: const Text('View All Stories'),
              onTap: _navigateToViewStoriesScreen,
            ),
            ListTile(
              leading: Icon(Icons.settings, color: greenColor),
              title: const Text('Change Password'),
              onTap: _navigateToChangePassword,
            ),
            ListTile(
              leading: Icon(Icons.supervised_user_circle, color: greenColor),
              title: const Text('User view story'),
              onTap: _navigateToUserHome,
            ),
          
          
            ListTile(
              leading: Icon(Icons.comment_outlined, color: greenColor),
              title: const Text('User view comments'),
              onTap: _navigateToStoryCommentsScreen,
            ),

            const SizedBox(height: 50),
            ListTile(
              leading: Icon(Icons.logout, color: greenColor),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Post a Story'),
        backgroundColor: greenColor,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Create a New Story',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: Icon(Icons.title, color: greenColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        alignLabelWithHint: true,
                      ),
                      minLines: 3,
                      maxLines: null,
                    ),
                    const SizedBox(height: 20),
                    if (_isSuccess)
                      Text(
                        'Story posted successfully!',
                        style: TextStyle(color: greenColor, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: _isPosting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Post Story'),
                        onPressed: _isPosting ? null : _postStory,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: greenColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Latest 5 Stories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('story')
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No stories posted yet.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final story = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(
                            story['title'] ?? 'No Title',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            story['content'] ?? 'No Content',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: greenColor),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => EditStoryScreen(
                                        docId: doc.id,
                                        initialTitle: story['title'] ?? '',
                                        initialContent: story['content'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('story')
                                      .doc(doc.id)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Story deleted')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}
