import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late GoogleMapController mapController;
  final Location _location = Location();
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  List<Map<String, dynamic>> clients = [];
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getLocation();
    _fetchClients();
  }

  void _getLocation() async {
    final loc = await _location.getLocation();
    setState(() {
      _currentPosition = LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0);
    });
  }

  void _fetchClients() async {
    final snapshot = await FirebaseFirestore.instance.collection('clients').get();
    final List<Map<String, dynamic>> loadedClients = [];
    final Set<Marker> clientMarkers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['latitude'];
      final lng = data['longitude'];

      if (lat != null && lng != null) {
        loadedClients.add({...data, 'id': doc.id});
        clientMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: data['name']),
          ),
        );
      }
    }

    setState(() {
      clients = loadedClients;
      _markers.addAll(clientMarkers);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _showAddCarModal(BuildContext context) {
    final plateCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    XFile? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Add New Car',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: plateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Car Number Plate',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: colorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Car Color',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.grey),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      selectedImage = image;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image Selected')),
                      );
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Upload Car Image'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (plateCtrl.text.isEmpty || colorCtrl.text.isEmpty || selectedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("All fields are required")),
                        );
                        return;
                      }

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                      final ref = FirebaseStorage.instance.ref().child('cars/$uid/$fileName');
                      await ref.putFile(File(selectedImage!.path));
                      final imageUrl = await ref.getDownloadURL();

                      await FirebaseFirestore.instance.collection('cars').add({
                        'plate': plateCtrl.text.trim(),
                        'color': colorCtrl.text.trim(),
                        'imageUrl': imageUrl,
                        'addedBy': uid,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Car added successfully')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Car'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCarModal(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Welcome, Admin!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 300,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: {
                Marker(
                  markerId: const MarkerId("admin_location"),
                  position: _currentPosition,
                  infoWindow: const InfoWindow(title: "Your Location"),
                ),
                ..._markers,
              },
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Available Clients',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: clients.isEmpty
                ? const Center(child: Text('No clients available'))
                : ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(client['name'] ?? 'No Name'),
                        subtitle: Text(
                            'Lat: ${client['latitude']}, Lng: ${client['longitude']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: () {
                            mapController.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(client['latitude'], client['longitude']),
                                16,
                              ),
                            );
                          },
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
