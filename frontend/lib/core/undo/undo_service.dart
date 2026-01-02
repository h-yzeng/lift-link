import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liftlink/core/undo/undo_action.dart';

/// Service for managing undo operations with persistence
class UndoService {
  final SharedPreferences _prefs;
  final List<UndoAction> _undoStack = [];
  final Duration _undoTimeout = const Duration(seconds: 5);
  final int _maxStackSize = 10;

  static const String _stackKey = 'undo_stack';

  UndoService(this._prefs) {
    _loadStack();
  }

  /// Load the undo stack from persistent storage
  Future<void> _loadStack() async {
    try {
      final stackJson = _prefs.getString(_stackKey);
      if (stackJson != null) {
        final decoded = jsonDecode(stackJson) as List<dynamic>;
        _undoStack.clear();
        _undoStack.addAll(
          decoded.map((json) => UndoAction.fromJson(json as Map<String, dynamic>)),
        );

        // Remove expired actions (older than 5 minutes)
        final now = DateTime.now();
        _undoStack.removeWhere(
          (action) => now.difference(action.createdAt).inMinutes > 5,
        );
      }
    } catch (e) {
      // If loading fails, start with empty stack
      _undoStack.clear();
    }
  }

  /// Save the undo stack to persistent storage
  Future<void> _saveStack() async {
    try {
      final stackJson = jsonEncode(
        _undoStack.map((action) => action.toJson()).toList(),
      );
      await _prefs.setString(_stackKey, stackJson);
    } catch (e) {
      // Silently fail - undo is a nice-to-have feature
    }
  }

  /// Add an action to the undo stack
  Future<void> addAction(UndoAction action) async {
    _undoStack.add(action);

    // Limit stack size
    if (_undoStack.length > _maxStackSize) {
      _undoStack.removeAt(0);
    }

    await _saveStack();
  }

  /// Get the most recent undo action without removing it
  UndoAction? peekLatest() {
    if (_undoStack.isEmpty) return null;
    return _undoStack.last;
  }

  /// Pop the most recent action from the stack
  Future<UndoAction?> popAction() async {
    if (_undoStack.isEmpty) return null;

    final action = _undoStack.removeLast();
    await _saveStack();
    return action;
  }

  /// Mark an action as executed
  Future<void> markExecuted(String actionId) async {
    final index = _undoStack.indexWhere((a) => a.id == actionId);
    if (index != -1) {
      _undoStack[index] = _undoStack[index].copyWith(executed: true);
      await _saveStack();
    }
  }

  /// Remove an action from the stack
  Future<void> removeAction(String actionId) async {
    _undoStack.removeWhere((a) => a.id == actionId);
    await _saveStack();
  }

  /// Clear all undo actions
  Future<void> clearStack() async {
    _undoStack.clear();
    await _saveStack();
  }

  /// Get the undo timeout duration
  Duration get undoTimeout => _undoTimeout;

  /// Get the current stack size
  int get stackSize => _undoStack.length;

  /// Check if the stack is empty
  bool get isEmpty => _undoStack.isEmpty;

  /// Get all actions in the stack (for debugging)
  List<UndoAction> get allActions => List.unmodifiable(_undoStack);
}
