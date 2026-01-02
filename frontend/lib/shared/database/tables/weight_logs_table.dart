import 'package:drift/drift.dart';

@DataClassName('WeightLogEntity')
class WeightLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  RealColumn get weight => real()();
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
