import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:deneme/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:deneme/services/firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: const TapPosition(),
    );
  }
}

class TapPosition extends StatefulWidget {
  const TapPosition({Key? key}) : super(key: key);

  @override
  State<TapPosition> createState() => _TapPositionState();
}

class _TapPositionState extends State<TapPosition> {
  double? _tapPositionLatitude;
  double? _tapPositionLongitude;

  final TextEditingController _buildingController = TextEditingController();
  String? _damageStatus;

  Future<List<DocumentSnapshot>>? buildings;

  void initState() {
    super.initState();
    buildings = FirestoreService().getBuildings();
  }

  void _getTapPosition(dynamic TapPosition, LatLng) async {
    print('details ${LatLng} tap ${TapPosition}');
    final tapPosition = LatLng;
    setState(() {
      _tapPositionLatitude = tapPosition.latitude;
      _tapPositionLongitude = tapPosition.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //onTapDown: (details) => _getTapPosition(details),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tapPositionLongitude != null
              ? 'Seçtiğiniz koordinat: X: ${_tapPositionLatitude}, Y: $_tapPositionLongitude}'
              : 'Seçim yapılmadı'),
        ),
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(38.34, 38.29),
                initialZoom: 15,
                onTap: _getTapPosition,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                FutureBuilder<List<DocumentSnapshot>>(
                  future: buildings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(); // or a loading indicator
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      List<DocumentSnapshot>? buildings = snapshot.data;
                      return MarkerLayer(
                        markers: buildings
                                ?.map((building) => _buildMarker(building))
                                .toList() ??
                            [],
                      );
                    }
                  },
                ),
              ],
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showSaveDialog(context);
          },
          child: Icon(Icons.save),
        ),
      ),
    );
  }

  Marker _buildMarker(DocumentSnapshot building) {
    double x = building['x koordinatı'];
    double y = building['y koordinatı'];
    print('building objesiiiiii  $x');
    String damageStatus = building['hasar durumu'];

    Color markerColor;
    if (damageStatus == 'Ağır hasarlı') {
      markerColor = Colors.red;
    } else if (damageStatus == 'Orta hasarlı') {
      markerColor = Colors.yellow;
    } else if (damageStatus == 'Hafif hasarlı') {
      markerColor = Colors.green;
    } else {
      markerColor = Colors.black;
    }

    return Marker(
      width: 40.0,
      height: 40.0,
      point: LatLng(y, x),
      child: Icon(
        color: markerColor,
        Icons.location_on,
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bina adını ve hasar durumunu giriniz'),
          content: Column(
            children: [
              TextField(
                controller: _buildingController,
                decoration: InputDecoration(labelText: 'Bina Adı'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _damageStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    _damageStatus = newValue;
                  });
                },
                items: ['Ağır hasarlı', 'Orta hasarlı', 'Hafif hasarlı']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                hint: Text('Hasar Durumu Seçin'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _saveMap(context);
                Navigator.pop(context);
              },
              child: Text('Kaydet'),
            ),
            TextButton(
              onPressed: () {
                print('Haritaya geri dönülüyor.');
                Navigator.pop(context);
              },
              child: Text('Geri Dön'),
            ),
          ],
        );
      },
    );
  }

  void _saveMap(BuildContext context) {
    if (_tapPositionLongitude != null &&
        _buildingController.text.isNotEmpty &&
        _damageStatus != null) {
      // Veritabanına eklemek için FirestoreService sınıfını kullan
      FirestoreService firestoreService = FirestoreService();

      // Koordinatları, bina adını ve hasar durumunu al
      double? xCoordinate = _tapPositionLongitude;
      double? yCoordinate = _tapPositionLatitude;
      String buildingName = _buildingController.text;
      String damageStatus = _damageStatus!;
      print('ximiz $xCoordinate ymiz $yCoordinate');
      // Veritabanına ekleme işlemini gerçekleştir
      firestoreService.addBuildings(
          xCoordinate, yCoordinate, buildingName, damageStatus);

      // Kullanıcıya bilgi mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bina Adı: $buildingName, Hasar Durumu: $damageStatus veri tabanına kaydedildi',
          ),
          duration: Duration(seconds: 10),
        ),
      );
    } else {
      // Eksik bilgi varsa kullanıcıya uyarı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Lütfen bina adı, hasar durumu seçimi ve haritaya bir nokta tıklayınız.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}
