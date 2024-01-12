import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference buildings =
      FirebaseFirestore.instance.collection('buildings');

  Future<void> addBuildings(double? x, double? y, String name, String hasar) {
    return buildings.add({
      'x koordinatı': x,
      'y koordinatı': y,
      'hasar durumu': hasar,
      'adı': name,
    });
  }

  Future<List<DocumentSnapshot>> getBuildings() async {
    QuerySnapshot querySnapshot = await buildings.get();
    return querySnapshot.docs;
  }
}
