import 'package:drift/drift.dart';

@DataClassName('ExerciseEntity')
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get muscleGroup => text()();
  TextColumn get equipmentType => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text().nullable()(); // User ID if custom
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // Track recent usage
  IntColumn get usageCount =>
      integer().withDefault(const Constant(0))(); // Track popularity
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
