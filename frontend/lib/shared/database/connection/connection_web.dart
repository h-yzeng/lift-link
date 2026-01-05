import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a connection to the database using WASM on web.
DatabaseConnection openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'liftlink_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );
      return result.resolvedExecutor;
    }),
  );
}
