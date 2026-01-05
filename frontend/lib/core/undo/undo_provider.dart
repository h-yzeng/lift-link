import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/core/undo/undo_service.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';

part 'undo_provider.g.dart';

@riverpod
Future<UndoService> undoService(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return UndoService(prefs);
}
