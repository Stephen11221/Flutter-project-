import 'package:flutter/material.dart';

class ViewStoryDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String postedDate;

  const ViewStoryDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.postedDate,
  });

  @override
  Widget build(BuildContext context) {
    final greenColor = Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Details'),
        backgroundColor: greenColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Posted on: $postedDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Divider(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
