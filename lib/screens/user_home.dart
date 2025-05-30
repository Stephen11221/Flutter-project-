import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String selectedVehicle = 'All';
  final searchController = TextEditingController();
  List<Map<String, dynamic>> cars = [];
  List<Map<String, dynamic>> filteredCars = [];
  Map<String, dynamic>? nearestCar;
  GoogleMapController? mapController;

  final vehicleTypes = ['All', 'Sedan', 'SUV', 'Truck', 'Van'];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchCars();
  }

  Future<void> _fetchCars() async {
    final snapshot = await FirebaseFirestore.instance.collection('cars').get();
    final carList = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      cars = List<Map<String, dynamic>>.from(carList);
      filteredCars = List.from(cars);
    });
  }

  void _filterCars() {
    String searchText = searchController.text.toLowerCase();
    setState(() {
      filteredCars = cars.where((car) {
        final plate = car['plate']?.toString().toLowerCase() ?? '';
        final color = car['color']?.toString().toLowerCase() ?? '';
        final matchSearch = plate.contains(searchText) || color.contains(searchText);
        final matchType = selectedVehicle == 'All' || (car['type'] == selectedVehicle);
        return matchSearch && matchType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = filteredCars.where((car) => car['lat'] != null && car['lng'] != null).map((car) {
      return Marker(
        markerId: MarkerId(car['id']),
        position: LatLng(car['lat'], car['lng']),
        infoWindow: InfoWindow(title: car['plate']),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Home"),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Cars",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by plate or color',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (_) => _filterCars(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: selectedVehicle,
                      items: vehicleTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedVehicle = value;
                            _filterCars();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0.0, 0.0),
                zoom: 2,
              ),
              markers: markers,
              myLocationEnabled: false,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredCars.isEmpty
                ? const Center(child: Text("No cars available"))
                : ListView.builder(
                    itemCount: filteredCars.length,
                    itemBuilder: (context, index) {
                      final car = filteredCars[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: car['imageUrl'] != null
                              ? Image.network(car['imageUrl'], width: 60, fit: BoxFit.cover)
                              : const Icon(Icons.directions_car),
                          title: Text(car['plate'] ?? 'Unknown Plate'),
                          subtitle: Text("Color: ${car['color'] ?? 'Unknown'}"),
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
