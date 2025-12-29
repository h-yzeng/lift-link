import 'package:drift/drift.dart';

@DataClassName('SetEntity')
class Sets extends Table {
  TextColumn get id => text()();
  TextColumn get exercisePerformanceId => text()();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  RealColumn get weightKg => real()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  BoolColumn get isDropset => boolean().withDefault(const Constant(false))();
  RealColumn get rpe => real().nullable()(); // Rate of Perceived Exertion (0-10)
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
