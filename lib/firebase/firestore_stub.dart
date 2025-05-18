// Stub implementation for Firestore

class FirebaseFirestore {
  static FirebaseFirestore instance = FirebaseFirestore._();
  FirebaseFirestore._();
  
  CollectionReference collection(String path) => CollectionReference();
  DocumentReference doc(String path) => DocumentReference();
}

class CollectionReference {
  Future<void> add(Map<String, dynamic> data) async {}
  DocumentReference doc([String? path]) => DocumentReference();
  Stream<QuerySnapshot> snapshots() => Stream.empty();
  Future<QuerySnapshot> get() async => QuerySnapshot();
}

class DocumentReference {
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {}
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
  Stream<DocumentSnapshot> snapshots() => Stream.empty();
  Future<DocumentSnapshot> get() async => DocumentSnapshot();
}

class QuerySnapshot {
  List<DocumentSnapshot> get docs => [];
}

class DocumentSnapshot {
  bool get exists => false;
  Map<String, dynamic>? get data => {};
  dynamic get(String field) => null;
  String get id => 'stub-id';
}
