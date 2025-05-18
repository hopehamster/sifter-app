// Stub implementation for Cloud Functions

class FirebaseFunctions {
  static FirebaseFunctions instance = FirebaseFunctions._();
  FirebaseFunctions._();
  
  HttpsCallable httpsCallable(String name) => HttpsCallable();
}

class HttpsCallable {
  Future<HttpsCallableResult> call([dynamic parameters]) async => HttpsCallableResult();
}

class HttpsCallableResult {
  dynamic get data => {'result': 'stub-result'};
}
