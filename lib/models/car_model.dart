import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String plate;
  final String color;
  final String imageUrl;
  final String addedBy;
  final DateTime? timestamp;

  Car({
    required this.id,
    required this.plate,
    required this.color,
    required this.imageUrl,
    required this.addedBy,
    this.timestamp,
  });

  factory Car.fromMap(Map<String, dynamic> data, String documentId) {
    return Car(
      id: documentId,
      plate: data['plate'] ?? '',
      color: data['color'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      addedBy: data['addedBy'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plate': plate,
      'color': color,
      'imageUrl': imageUrl,
      'addedBy': addedBy,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }
}
