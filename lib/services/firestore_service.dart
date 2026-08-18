import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';


class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('tasks');

  Future<List<Task>> fetchAllTasks() async {
    final snapshot = await _tasksRef.get();
    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Stream<List<Task>> watchTasks() {
    return _tasksRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Task.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> upsertTask(Task task) async {
    await _tasksRef.doc(task.id).set(task.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
  }
}
