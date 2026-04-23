import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseDatabaseService {
  FirebaseDatabaseService({FirebaseDatabase? database}) : _database = database;

  FirebaseDatabase? _database;

  static FirebaseDatabase _buildDatabase() {
    // Replace this with your exact RTDB URL if the instance was created in a
    // specific region and does not use the default project-based URL.
    const databaseUrl = String.fromEnvironment(
      'FIREBASE_DATABASE_URL',
      defaultValue: 'https://safe-call-ai-default-rtdb.firebaseio.com',
    );

    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
  }

  Future<void> saveCallLog({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    final database = _database ??= _buildDatabase();
    await database.ref('call_logs/$id').set(data);
  }

  Stream<List<Map<String, dynamic>>> watchCallLogs() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }
    final database = _database ??= _buildDatabase();
    return database.ref('call_logs').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return const <Map<String, dynamic>>[];
      }

      final entries = value.entries.map((entry) {
        final raw = entry.value;
        final map = raw is Map ? Map<Object?, Object?>.from(raw) : <Object?, Object?>{};
        return <String, dynamic>{
          'id': entry.key.toString(),
          ...map.map(
            (key, item) => MapEntry(key.toString(), item),
          ),
        };
      }).toList();

      entries.sort((a, b) {
        final aTimestamp = a['timestamp_ms'] as num? ?? 0;
        final bTimestamp = b['timestamp_ms'] as num? ?? 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      return entries;
    });
  }
}
