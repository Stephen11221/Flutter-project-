import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditStoryScreen extends StatefulWidget {
  final String docId;
  final String initialTitle;
  final String initialContent;

  const EditStoryScreen({
    super.key,
    required this.docId,
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  State<EditStoryScreen> createState() => _EditStoryScreenState();
}

class _EditStoryScreenState extends State<EditStoryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  void _updateStory() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content cannot be empty')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    await FirebaseFirestore.instance.collection('story').doc(widget.docId).update({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
    });

    setState(() => _isUpdating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Story updated successfully!')),
    );

    Navigator.of(context).pop(); // Return to previous screen
  }

  @override
  Widget build(BuildContext context) {
    final greenColor = Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Story'),
        backgroundColor: greenColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: null,
              minLines: 6,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Update Story'),
                onPressed: _isUpdating ? null : _updateStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
