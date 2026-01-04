import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Opens a connection to the database using IndexedDB on web.
QueryExecutor openConnection() {
  return WebDatabase('liftlink_db');
}
