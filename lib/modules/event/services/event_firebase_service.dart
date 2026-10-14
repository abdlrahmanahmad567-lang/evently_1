import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventFirebaseService {
  static const String collectionName = "Events";

  static CollectionReference<EventModel> getEventsCollection() {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .withConverter<EventModel>(
          fromFirestore: (snapshot, _) =>
              EventModel.fromJson(snapshot.data()!, id: snapshot.id),
          toFirestore: (event, _) => event.toJson(),
        );
  }




  static Future<void> addEvent(EventModel event) async {
    var collection = getEventsCollection();
    var doc = collection.doc();
    event.id = doc.id;
    await doc.set(event);
  }

  static Future<void> updateEvent(EventModel event) async {
    if (event.id == null) return;
    await getEventsCollection()
        .doc(event.id)
        .set(event, SetOptions(merge: true));
  }

  static Future<void> deleteEvent(String id) async {
    await getEventsCollection().doc(id).delete();
  }

  static Future<void> toggleFavorite(EventModel event) async {
    if (event.id == null) return;
    event.isFavorite = !event.isFavorite;
    await getEventsCollection()
        .doc(event.id)
        .set(event, SetOptions(merge: true));
  }

  static Stream<List<EventModel>> getEventsStream({String? categoryId}) {
    var uid = FirebaseAuth.instance.currentUser?.uid;
    return getEventsCollection().snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => doc.data()).toList();
      if (uid != null && uid.isNotEmpty) {
        list = list.where((e) => e.userId == uid || e.userId.isEmpty).toList();
      }
      list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          categoryId.toLowerCase() != 'all') {
        final target = categoryId.trim().toLowerCase();
        list = list.where((e) {
          return e.categoryId.trim().toLowerCase() == target ||
              e.categoryTitle.trim().toLowerCase() == target;
        }).toList();
      }
      return list;
    });
  }

  static Stream<List<EventModel>> getFavoritesStream() {
    var uid = FirebaseAuth.instance.currentUser?.uid;
    return getEventsCollection().snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => doc.data()).toList();
      if (uid != null && uid.isNotEmpty) {
        list = list.where((e) => e.userId == uid || e.userId.isEmpty).toList();
      }
      list = list.where((e) => e.isFavorite).toList();
      list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return list;
    });
  }

  static Stream<DocumentSnapshot<EventModel>> getEventStream(String id) {
    return getEventsCollection().doc(id).snapshots();
  }
}
