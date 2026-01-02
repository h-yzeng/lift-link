import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/shared/database/app_database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  return AppDatabase();
}
