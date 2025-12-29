import 'package:drift/drift.dart';

@DataClassName('FriendshipEntity')
class Friendships extends Table {
  TextColumn get id => text()();
  TextColumn get requesterId => text()();
  TextColumn get addresseeId => text()();
  TextColumn get status => text()(); // pending, accepted, rejected
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
