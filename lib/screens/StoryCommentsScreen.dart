import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';

class ViewCommentsScreen extends StatelessWidget {
  final String storyId;

  ViewCommentsScreen({required this.storyId});

  Future<Map<String, double>> _getRatingSummary(String storyId) async {
    final ratingDoc = await FirebaseFirestore.instance
        .collection('ratings')
        .doc(storyId)
        .get();

    final ratings = (ratingDoc.data()?['ratings'] ?? {}) as Map<String, dynamic>;

    Map<int, int> ratingCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var r in ratings.values) {
      if (r is int && ratingCount.containsKey(r)) {
        ratingCount[r] = ratingCount[r]! + 1;
      }
    }

    return {
      "5 Stars": ratingCount[5]!.toDouble(),
      "4 Stars": ratingCount[4]!.toDouble(),
      "3 Stars": ratingCount[3]!.toDouble(),
      "2 Stars": ratingCount[2]!.toDouble(),
      "1 Star": ratingCount[1]!.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final commentStream = FirebaseFirestore.instance
        .collection('comments')
        .where('storyId', isEqualTo: storyId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Comments & Ratings'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Ratings Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          FutureBuilder<Map<String, double>>(
            future: _getRatingSummary(storyId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final ratingSummary = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: PieChart(
                  dataMap: ratingSummary,
                  chartRadius: MediaQuery.of(context).size.width / 2.2,
                  colorList: [Colors.green, Colors.lightGreen, Colors.yellow, Colors.orange, Colors.red],
                  legendOptions: const LegendOptions(legendPosition: LegendPosition.right),
                  chartValuesOptions: const ChartValuesOptions(showChartValuesInPercentage: true),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "Comments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: commentStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(child: Text("No comments found."));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var comment = comments[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.comment, color: Colors.green),
                        title: Text(comment['userName'] ?? 'Anonymous'),
                        subtitle: Text(comment['text'] ?? ''),
                        trailing: comment.containsKey('rating')
                            ? Text("⭐ ${comment['rating']}")
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
