import 'package:drift/drift.dart';

/// Conditional import stub that will be replaced by platform-specific implementations.
/// This file should never be used directly - it's only for static analysis.
QueryExecutor openConnection() {
  throw UnsupportedError(
    'Cannot create a database connection without dart:html or dart:io support.',
  );
}
