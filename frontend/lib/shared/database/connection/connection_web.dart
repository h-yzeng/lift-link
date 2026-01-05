import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a connection to the database using WASM on web.
Future<QueryExecutor> openConnection() async {
  final result = await WasmDatabase.open(
    databaseName: 'liftlink_db',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  return result.resolvedExecutor;
}
