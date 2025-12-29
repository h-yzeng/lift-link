import 'package:drift/drift.dart';

@DataClassName('ProfileEntity')
class Profiles extends Table {
  TextColumn get id => text()(); // UUID from Supabase
  TextColumn get username => text().withLength(min: 3, max: 50)();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()(); // Last sync timestamp

  @override
  Set<Column> get primaryKey => {id};
}
