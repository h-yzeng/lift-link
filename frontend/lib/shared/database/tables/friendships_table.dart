import 'package:drift/drift.dart';

@DataClassName('FriendshipEntity')
class Friendships extends Table {
  TextColumn get id => text()();
  TextColumn get requesterId => text()();
  TextColumn get addresseeId => text()();
  TextColumn get status => text()(); // pending, accepted, rejected
  TextColumn get requesterNickname => text().nullable()(); // Nickname given by requester to addressee
  TextColumn get addresseeNickname => text().nullable()(); // Nickname given by addressee to requester
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
